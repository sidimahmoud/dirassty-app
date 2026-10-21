import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../l10n/app_localizations.dart';
import '../theme/dirassty_theme.dart';
import '../widgets/dirassty/dirassty_context.dart';

/// App-wide screenshot / screen-recording protection, mounted once via
/// `MaterialApp.builder` (see DirasstyApp).
///
/// - Android: `FLAG_SECURE` — screenshots and recordings (including
///   casting and the recent-apps thumbnail) come out black. Also set
///   natively in MainActivity.kt so it's on from the very first frame,
///   before this widget mounts.
/// - iOS: Apple offers no API to block screenshots outright. This uses
///   the secure-layer technique (the same one password fields use), which
///   makes screenshots and recordings capture a black screen, plus a
///   black cover whenever `UIScreen.isCaptured` reports an active
///   recording/AirPlay mirror, and a black app-switcher snapshot.
///
/// Off in debug builds (see [_ScreenCaptureGuardState._enable]) so the app
/// is visible on emulators/simulators while developing — to test the
/// protection itself, run a release build on a real device.
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
    _enable();
  }

  Future<void> _enable() async {
    // Release/profile builds only — in debug, emulator/simulator screen
    // mirroring is itself a capture and would render the whole app black.
    if (kDebugMode) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      if (!Platform.isIOS) return;
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
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
        if (_isBeingCaptured) const Positioned.fill(child: _ProtectedScreen()),
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
