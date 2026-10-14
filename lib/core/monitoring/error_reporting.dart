import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../features/auth/application/app_auth_state.dart';

/// Production error tracking (Sentry). Off unless the build passes a DSN —
/// release builds read it from config/prod.json:
///   flutter build apk --release --dart-define-from-file=config/prod.json
/// (see config/README.md). Without a DSN this is a no-op and the app runs
/// exactly as before; a malformed DSN never blocks startup either.
///
/// Users are children: nothing personal is sent — no names, phone
/// numbers, IP address, screenshots or view hierarchy; only the error,
/// stack trace, device/OS/app version, and an account id + role.
///
/// The free Sentry plan counts every event (5,000 / month), so
/// [_QuotaGuard] makes each phone report each distinct bug only a few
/// times per session, caps a session's total, and keeps connectivity
/// noise to one sample — one bug hitting every user, or a crash loop on
/// one phone, can't burn the month's quota and hide new bugs.
abstract final class ErrorReporting {
  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _environment =
      String.fromEnvironment('SENTRY_ENV', defaultValue: 'production');

  /// Never from debug runs (`flutter run` without --release): those are
  /// the developer's own errors and would only spend quota.
  static bool get enabled => _dsn.isNotEmpty && !kDebugMode;

  static final _QuotaGuard _guard = _QuotaGuard();

  /// Starts Sentry (when enabled), then runs the app inside it so Flutter
  /// framework errors, uncaught async errors and native crashes are all
  /// reported.
  static Future<void> start(Widget app) async {
    if (!enabled) {
      runApp(app);
      return;
    }
    try {
      await SentryFlutter.init(
        (SentryFlutterOptions o) {
          o.dsn = _dsn;
          o.environment = _environment;
          o.sendDefaultPii = false;
          o.attachScreenshot = false; // view hierarchy is off by default too
          // Errors only — performance tracing would eat the free quota.
          o.tracesSampleRate = 0;
          o.beforeSend = (SentryEvent event, Hint hint) => _guard.filter(event);
        },
        appRunner: () => runApp(SentryWidget(child: app)),
      );
    } catch (_) {
      // Bad DSN / SDK failure: run the app without error reporting.
      runApp(app);
    }
  }

  /// Tags every following report with the signed-in account (id + role
  /// only), so an error can be matched to a support request.
  static void identify(AppAuthState state) {
    if (!enabled) return;
    final (String? id, String? role) = switch (state) {
      AppAuthParent(:final userId) => (userId, 'parent'),
      AppAuthStudent(:final userId) => (userId, 'student'),
      _ => (null, null),
    };
    Sentry.configureScope((Scope scope) {
      scope.setUser(id == null ? null : SentryUser(id: id));
      if (role == null) {
        scope.removeTag('role');
      } else {
        scope.setTag('role', role);
      }
    });
  }
}

/// Per-session (per app launch) budget for what gets sent to Sentry.
class _QuotaGuard {
  /// Same bug (type + message) reported at most this many times.
  static const int maxPerBug = 3;

  /// Connectivity errors (no network, timeout, DNS…) are common on mobile
  /// data and not code bugs: one sample per session shows if one spreads.
  static const int maxPerNetworkError = 1;

  /// Hard cap for everything in one session (crash loops, cascades).
  static const int maxPerSession = 20;

  static final RegExp _network = RegExp(
    r'SocketException|HandshakeException|TimeoutException|ClientException|'
    r'NetworkImageLoadException|AuthRetryableFetchException|'
    r'Failed host lookup|Connection (closed|reset|refused)|Network is unreachable|'
    r'Software caused connection abort|ERR_INTERNET_DISCONNECTED',
    caseSensitive: false,
  );

  final Map<String, int> _seen = {};
  int _total = 0;

  SentryEvent? filter(SentryEvent event) {
    if (_total >= maxPerSession) return null;
    final SentryException? ex =
        event.exceptions?.isNotEmpty == true ? event.exceptions!.first : null;
    final String type = ex?.type ?? 'message';
    final String value = ex?.value ?? event.message?.formatted ?? '';
    // Digits stripped so "took 1532ms" / ids don't make every event unique.
    final String raw = '$type|${value.replaceAll(RegExp(r'\d+'), '#')}';
    final String key = raw.length > 200 ? raw.substring(0, 200) : raw;
    final bool network = _network.hasMatch('$type $value');
    final int limit = network ? maxPerNetworkError : maxPerBug;
    final int count = _seen[key] ?? 0;
    if (count >= limit) return null;
    _seen[key] = count + 1;
    _total++;
    if (network) event.tags = {...?event.tags, 'kind': 'network'};
    return event;
  }
}
