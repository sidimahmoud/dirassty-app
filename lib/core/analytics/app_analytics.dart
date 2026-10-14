import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/auth_providers.dart';

/// Product / funnel events → the Dirassty database (`app_events`, through
/// the `track_events` RPC — see docs/marketing-events.md). Not Airbridge:
/// that one only gets marketing conversions (Phase 3).
///
/// Cheap on purpose (Supabase cost rule): events are queued and sent in
/// one batch a few seconds later (or when the app goes to background —
/// [flush]), only for a signed-in user. Never throws, never blocks: a lost
/// analytics event is acceptable, a broken payment flow is not.
class AppAnalytics {
  AppAnalytics(this._client);

  final SupabaseClient _client;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  String? _appVersion;

  static const Duration _delay = Duration(seconds: 4);
  static const int _maxBatch = 20;

  /// Queues [name] (must be whitelisted server-side) with [properties].
  void track(String name, [Map<String, Object?> properties = const {}]) {
    if (kIsWeb || _client.auth.currentSession == null) return;
    _queue.add({
      'name': name,
      'properties': {
        for (final MapEntry<String, Object?> e in properties.entries)
          if (e.value != null) e.key: e.value,
      },
      'platform':
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    if (_queue.length >= _maxBatch) {
      unawaited(flush());
    } else {
      _timer ??= Timer(_delay, () => unawaited(flush()));
    }
  }

  /// Sends everything queued now (app paused, sign-out…).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty || _client.auth.currentSession == null) return;
    final List<Map<String, dynamic>> batch = List.of(_queue);
    _queue.clear();
    try {
      _appVersion ??= await PackageInfo.fromPlatform()
          .then((i) => '${i.version}+${i.buildNumber}')
          .catchError((_) => '');
      for (final Map<String, dynamic> e in batch) {
        e['app_version'] = _appVersion;
      }
      await _client.rpc<dynamic>('track_events', params: {'p_events': batch});
    } catch (_) {
      // Offline / RPC missing: drop — analytics must never break the app.
    }
  }

  /// Applies a promo / influencer code for the signed-in account
  /// (`apply_promo_code`, tracking only — no discount). Returns the
  /// influencer's name when the code is valid, null otherwise.
  Future<String?> applyPromoCode(String code, {required String context}) async {
    final String trimmed = code.trim();
    if (trimmed.isEmpty || _client.auth.currentSession == null) return null;
    try {
      final dynamic res = await _client.rpc<dynamic>('apply_promo_code',
          params: {'p_code': trimmed, 'p_context': context});
      if (res is Map && res['ok'] == true) {
        return res['influencer'] as String? ?? '';
      }
    } catch (_) {
      // Ignore — a code must never block signup or payment.
    }
    return null;
  }
}

final Provider<AppAnalytics> appAnalyticsProvider =
    Provider((ref) => AppAnalytics(ref.watch(supabaseClientProvider)));
