import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../l10n/app_localizations.dart';
import '../theme/dirassty_theme.dart';
import '../widgets/dirassty/dirassty_context.dart';

/// Screenshot / screen-recording protection for the learning flow only —
/// lessons, videos, QCM, open exercises and exams. Every other screen
/// (home, profile, subscriptions, parent space…) can be captured freely.
///
/// A screen opts in by wrapping itself in [CaptureProtected] (the router
/// does it for the learning routes; [CourseVideoPlayer] does it wherever a
/// video plays, e.g. Downloads). Protection is on while at least one is
/// mounted and goes off when the last one leaves:
///
/// - Android: `FLAG_SECURE` — screenshots and recordings (including
///   casting and the recent-apps thumbnail) come out black.
/// - iOS: Apple offers no API to block screenshots outright. This uses
///   the secure-layer technique (the same one password fields use), which
///   makes screenshots and recordings capture a black screen, plus a
///   black cover ([ScreenCaptureGuard]) whenever `UIScreen.isCaptured`
///   reports an active recording/AirPlay mirror, and a black app-switcher
///   snapshot.
///
/// Off in debug builds so the app is visible on emulators/simulators while
/// developing — to test the protection itself, run a release build on a
/// real device.
class CaptureProtection {
  CaptureProtection._();

  static int _holders = 0;
  static bool _applied = false;
  static Future<void> _queue = Future<void>.value();

  /// True while a protected screen is mounted.
  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  static void _acquire() {
    _holders++;
    _sync();
  }

  static void _release() {
    if (_holders > 0) _holders--;
    _sync();
  }

  /// Applies the wanted state in order — screens come and go faster than
  /// the platform calls finish, so each step re-reads the latest count.
  static void _sync() {
    active.value = _holders > 0;
    if (kDebugMode) return;
    _queue = _queue.then((_) async {
      final bool want = _holders > 0;
      if (want == _applied) return;
      try {
        if (want) {
          await ScreenProtector.preventScreenshotOn();
          if (Platform.isIOS) {
            await ScreenProtector.protectDataLeakageWithColor(Colors.black);
          }
        } else {
          await ScreenProtector.preventScreenshotOff();
          if (Platform.isIOS) {
            await ScreenProtector.protectDataLeakageWithColorOff();
          }
        }
        _applied = want;
      } catch (e) {
        debugPrint('CaptureProtection: $e');
      }
    });
  }
}

/// Turns [CaptureProtection] on while this widget is mounted.
class CaptureProtected extends StatefulWidget {
  const CaptureProtected({required this.child, super.key});

  final Widget child;

  @override
  State<CaptureProtected> createState() => _CaptureProtectedState();
}

class _CaptureProtectedState extends State<CaptureProtected> {
  @override
  void initState() {
    super.initState();
    CaptureProtection._acquire();
  }

  @override
  void dispose() {
    CaptureProtection._release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Mounted once via `MaterialApp.builder` (see DirasstyApp): on iOS,
/// covers the app with [_ProtectedScreen] while a recording / mirror is
/// running AND a protected screen is open. Blocks nothing by itself.
class ScreenCaptureGuard extends StatefulWidget {
  const ScreenCaptureGuard({required this.child, super.key});

  final Widget child;

  @override
  State<ScreenCaptureGuard> createState() => _ScreenCaptureGuardState();
}

class _ScreenCaptureGuardState extends State<ScreenCaptureGuard> {
  bool _isBeingCaptured = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    if (kDebugMode || !Platform.isIOS) return;
    try {
      ScreenProtector.addListener(null, (bool isCaptured) {
        if (mounted) setState(() => _isBeingCaptured = isCaptured);
      });
      final bool recording = await ScreenProtector.isRecording();
      if (mounted) setState(() => _isBeingCaptured = recording);
    } catch (e) {
      debugPrint('ScreenCaptureGuard: $e');
    }
  }

  @override
  void dispose() {
    if (!kDebugMode && Platform.isIOS) ScreenProtector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBeingCaptured)
          ValueListenableBuilder<bool>(
            valueListenable: CaptureProtection.active,
            builder: (context, protectedNow, _) => protectedNow
                ? const Positioned.fill(child: _ProtectedScreen())
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// Black cover while iOS reports an active recording / mirror: lock
/// badge, "Enregistrement d'écran non autorisé" and why.
/// DESIGN_SPEC §2 "Protected screen".
class _ProtectedScreen extends StatelessWidget {
  const _ProtectedScreen();

  static const Color _bodyColor = Color(0xFFB7C1BE);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: DirasstySpace.lg),
              Text(
                l10n.screenRecordingBlocked,
                textAlign: TextAlign.center,
                style: type.subheading.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DirasstySpace.sm),
              Text(
                l10n.screenRecordingBody,
                textAlign: TextAlign.center,
                style: type.bodySmall.copyWith(color: _bodyColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
