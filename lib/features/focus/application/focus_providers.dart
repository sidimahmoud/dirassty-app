import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/focus_settings.dart';
import '../../../core/models/student.dart';
import '../../auth/application/app_auth_state.dart';
import '../../auth/application/auth_providers.dart';
import '../../student/application/student_providers.dart';
import '../data/focus_lock_platform.dart';
import '../data/focus_repository.dart';

final Provider<FocusRepository> focusRepositoryProvider = Provider(
  (ref) => FocusRepository(ref.watch(supabaseClientProvider)),
);

// ── Parent side ──────────────────────────────────────────────────

final focusSettingsForStudentProvider =
    FutureProvider.family<FocusSettings, String>((ref, studentId) {
  return ref.watch(focusRepositoryProvider).getSettings(studentId);
});

final focusEventsForStudentProvider =
    FutureProvider.family<List<FocusEvent>, String>((ref, studentId) {
  return ref.watch(focusRepositoryProvider).getRecentEvents(studentId);
});

// ── Student side ─────────────────────────────────────────────────

@immutable
class FocusLockState {
  const FocusLockState({
    this.settings,
    this.activeUntil,
    this.isLocked = false,
  });

  final FocusSettings? settings;

  /// Non-null while focus mode is in effect — when the current window
  /// ends.
  final DateTime? activeUntil;

  /// Android: the app is pinned. iOS: Guided Access is on.
  final bool isLocked;

  bool get isActive => activeUntil != null;
}

/// Enforces the signed-in student's focus schedule on this device.
///
/// Settings come from the last successful fetch (cached on the device),
/// so a schedule keeps applying with no connection. Re-evaluated on a
/// short timer while the app is open — cheap local date math, no network
/// — and refetched on every app resume, so a parent's change lands the
/// next time the student opens the app.
class FocusLockController extends Notifier<FocusLockState> {
  final FocusLockPlatform _platform = const FocusLockPlatform();
  Timer? _ticker;
  String? _studentId;
  DateTime? _overrideUntil;

  FocusRepository get _repo => ref.read(focusRepositoryProvider);

  @override
  FocusLockState build() {
    ref.onDispose(() => _ticker?.cancel());
    final AppAuthState? auth = ref.watch(appAuthStateProvider).valueOrNull;
    final Student? student = auth is AppAuthStudent
        ? ref.watch(currentStudentProvider).valueOrNull
        : null;
    _studentId = student?.id;
    _init();
    return stateOrNull ?? const FocusLockState();
  }

  Future<void> _init() async {
    final FocusSettings? cached = await _repo.readCachedSettings();
    _overrideUntil = await _repo.readOverrideUntil();
    if (cached != null)
      state = FocusLockState(settings: cached, isLocked: state.isLocked);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _evaluate());
    await _evaluate();
    await refresh();
  }

  /// Refetches this student's settings (called on start and app resume).
  Future<void> refresh() async {
    final String? studentId = _studentId;
    if (studentId == null) return;
    try {
      final FocusSettings fresh = await _repo.getSettings(studentId);
      await _repo.cacheSettings(fresh);
      state = FocusLockState(
        settings: fresh,
        activeUntil: state.activeUntil,
        isLocked: state.isLocked,
      );
      await _repo.flushEvents();
    } catch (_) {
      // Offline — keep enforcing the cached copy.
    }
    await _evaluate();
  }

  Future<void> _evaluate() async {
    final DateTime now = DateTime.now();
    final bool overridden =
        _overrideUntil != null && now.isBefore(_overrideUntil!);
    final DateTime? until =
        overridden ? null : state.settings?.activeUntil(now);

    final bool wasActive = state.isActive;
    bool locked = await _platform.isLocked();
    // Android: the student did the system unpin gesture mid-window.
    if (until != null &&
        wasActive &&
        state.isLocked &&
        !locked &&
        _platform.canSelfPin) {
      final String? studentId = _studentId;
      if (studentId != null) {
        await _repo.logEvent(
          studentId,
          FocusEvent(kind: 'left_app', occurredAt: now),
        );
      }
    }
    if (until != null && !locked && _platform.canSelfPin) {
      await _platform.pin();
      locked = await _platform.isLocked();
    } else if (until == null && wasActive && _platform.canSelfPin) {
      await _platform.unpin();
      locked = false;
    }
    state = FocusLockState(
        settings: state.settings, activeUntil: until, isLocked: locked);
  }

  /// Wire to the app's lifecycle (see DirasstyApp.didChangeAppLifecycleState).
  Future<void> onLifecycle(AppLifecycleState lifecycle) async {
    if (lifecycle == AppLifecycleState.resumed) {
      await refresh();
      return;
    }
    // A pinned/Guided-Access app can still be paused by the screen
    // turning off — only an unprotected pause while focus is on means
    // the student actually switched away.
    if (lifecycle == AppLifecycleState.paused && state.isActive) {
      final String? studentId = _studentId;
      if (studentId != null && !await _platform.isLocked()) {
        await _repo.logEvent(
          studentId,
          FocusEvent(kind: 'left_app', occurredAt: DateTime.now()),
        );
      }
    }
  }

  /// Ends focus mode early (until the current window's end) if [pin] is
  /// the parent's PIN.
  Future<bool> unlockWithPin(String pin) async {
    final DateTime? until = state.activeUntil;
    final String? studentId = _studentId;
    if (until == null || !(state.settings?.verifyPin(pin) ?? false))
      return false;
    _overrideUntil = until;
    await _repo.writeOverrideUntil(until);
    await _platform.unpin();
    state = FocusLockState(settings: state.settings);
    if (studentId != null) {
      await _repo.logEvent(
        studentId,
        FocusEvent(kind: 'pin_unlock', occurredAt: DateTime.now()),
      );
    }
    return true;
  }
}

final NotifierProvider<FocusLockController, FocusLockState>
    focusLockControllerProvider =
    NotifierProvider<FocusLockController, FocusLockState>(
  FocusLockController.new,
);
