import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/app_analytics.dart';
import '../core/analytics/install_attribution.dart';
import '../core/layout/system_bars.dart';
import '../core/update/app_update.dart';
import '../core/update/update_gate.dart';
import '../core/monitoring/error_reporting.dart';
import '../core/i18n/app_lang.dart';
import '../core/i18n/app_language_provider.dart';
import '../core/layout/responsive.dart';
import '../core/offline/offline_videos_controller.dart';
import '../core/push/push_banner.dart';
import '../core/push/push_providers.dart';
import '../core/push/push_service.dart';
import '../core/router/app_router.dart';
import '../core/security/screen_capture_guard.dart';
import '../core/theme/dirassty_theme.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/application/app_auth_state.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/focus/application/focus_providers.dart';
import '../features/focus/presentation/focus_mode_overlay.dart';
import '../features/parent/application/parent_providers.dart';
import '../features/student/application/student_providers.dart';
import '../features/subscription/application/subscription_providers.dart';
import 'splash_overlay.dart';

/// Root widget — owns the app-wide [MaterialApp.router], theme, and
/// localization config. Everything else lives under `features/`.
class DirasstyApp extends ConsumerStatefulWidget {
  const DirasstyApp({super.key});

  @override
  ConsumerState<DirasstyApp> createState() => _DirasstyAppState();
}

class _DirasstyAppState extends ConsumerState<DirasstyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Android: which tracking link (if any) brought this install.
    ref.read(installAttributionProvider).checkFirstLaunch();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(focusLockControllerProvider.notifier).onLifecycle(state);
    // Send queued funnel events before the OS may kill the app.
    if (state == AppLifecycleState.paused) {
      ref.read(appAnalyticsProvider).flush();
    }
    if (state != AppLifecycleState.resumed) return;
    // Nothing pushes changes to the client — no realtime channel is kept
    // open for this on purpose (see CLAUDE.md's Supabase cost-discipline
    // rule: a channel per user for something this infrequent isn't worth
    // it). So an admin activating a subscription, or a parent's payment
    // being verified, while this device was backgrounded would otherwise
    // sit invisible in these cached providers until the app was fully
    // force-quit and reopened. Refetch on every resume instead — cheap
    // (a handful of indexed reads), and makes "he's on his profile screen
    // and it still says unpaid" resolve itself the next time he checks.
    // A new minimum/latest version set by an admin shows up on resume.
    ref.invalidate(appUpdateStatusProvider);
    ref.invalidate(currentStudentProvider);
    ref.invalidate(currentParentProvider);
    ref.invalidate(subscriptionsByParentProvider);
    ref.invalidate(latestSubscriptionsByStudentProvider);
    ref.invalidate(upcomingSubscriptionsByStudentProvider);
    // Family providers — invalidating the family itself (no specific
    // argument) refreshes every live instance, regardless of which
    // student it's keyed by.
    ref.invalidate(subscriptionForStudentProvider);
    ref.invalidate(upcomingSubscriptionForStudentProvider);
    ref.invalidate(studentHasAccessProvider);
  }

  /// Registers this device for push notifications the moment a
  /// parent/student session resolves — re-fires on every sign-in (a
  /// shared device switching accounts re-points its token at the new
  /// owner; see PushService.registerCurrentDevice). A first-time
  /// parent who hasn't finished registration (`needsOnboarding`) has no
  /// real `parents` row yet, so registering now would violate
  /// `device_tokens.parent_id`'s foreign key — skipped until that
  /// completes, same as every other parent-scoped fetch in this app.
  ///
  /// Also subscribes the device to its broadcast topics (its class for a
  /// student, each child's class for a parent) and, on sign-out, removes
  /// it from them so a shared phone stops getting the last account's
  /// notifications.
  void _registerDeviceForPush(AppAuthState state) {
    ErrorReporting.identify(state);
    if (state is AppAuthParent || state is AppAuthStudent) {
      // Attribute the account to the link that brought the install.
      ref.read(installAttributionProvider).claimIfPending();
    }
    final push = ref.read(pushServiceProvider);
    switch (state) {
      case AppAuthParent(needsOnboarding: false, :final userId):
        ref.read(studentsByParentProvider.future).then(
              (children) => push.registerCurrentDevice(
                parentId: userId,
                topics: PushService.parentTopics(children.map((c) => c.grade)),
              ),
              onError: (_) => push.registerCurrentDevice(
                parentId: userId,
                topics: PushService.parentTopics(const []),
              ),
            );
      case AppAuthStudent():
        ref.read(currentStudentProvider.future).then((student) {
          push.registerCurrentDevice(
            studentRowId: student.id,
            topics: PushService.studentTopics(student.grade),
          );
        });
      case AppAuthUnauthenticated():
        push.signOut();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLang lang = ref.watch(appLanguageProvider);
    ref.listen<AsyncValue<AppAuthState>>(appAuthStateProvider, (
      previous,
      next,
    ) {
      final AppAuthState? state = next.valueOrNull;
      if (state != null) _registerDeviceForPush(state);
    });
    // Kept alive app-wide (not just while a video screen is open) so every
    // successful subscription fetch re-syncs offline access — a lapsed
    // plan wipes downloads even if the student never opens a lesson.
    ref.listen(offlineVideosControllerProvider, (_, __) {});
    // Same reason: focus mode must enforce the parent's schedule on
    // whatever screen the student is on, not only after some screen reads it.
    ref.listen(focusLockControllerProvider, (_, __) {});
    return MaterialApp.router(
      title: 'Dirassty',
      debugShowCheckedModeBanner: false,
      // Design-handoff theme: Inter for French, Cairo for Arabic, same scale.
      theme: DirasstyTheme.light(lang.flutterLocale),
      routerConfig: ref.watch(goRouterProvider),
      // The single point that makes every screen tablet/iPad-friendly —
      // see ResponsiveShell's doc comment. A no-op on phone widths.
      builder: (context, child) => ScreenCaptureGuard(
        child: SplashOverlay(
          child: UpdateGate(
            child: PushBannerHost(
              child: FocusModeOverlay(
                  child: ResponsiveShell(
                      child: SystemNavigationInset(
                          child: child ?? const SizedBox.shrink()))),
            ),
          ),
        ),
      ),
      // Arabic is a full app locale (not just a content language) since
      // parents/students can run the whole UI chrome in Arabic — RTL is
      // handled by Flutter automatically once `ar` is the active locale.
      // Explicit `locale` (not left to system resolution) so the
      // Profile screen's language toggle actually controls the app,
      // persisted via appLanguageProvider.
      locale: lang.flutterLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      // App copy lives in lib/l10n/app_{fr,ar}.arb (generated
      // AppLocalizations); screens still using inline `isArabic ? … : …`
      // strings move over as they're redesigned.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
