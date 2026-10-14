import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/focus_settings.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/auth_errors.dart';
import '../application/focus_providers.dart';
import 'focus_blocked_dialog.dart';

/// Mounted once via `MaterialApp.builder` (see DirasstyApp): while focus
/// mode is active, puts [FocusModeBar] above every screen and, on
/// "Déverrouiller", the parent-PIN sheet (PinBoxes + PinPad + the iOS
/// Guided Access hint). A correct PIN ends the current window and is
/// logged by [FocusLockController.unlockWithPin].
///
/// This sits above the Navigator, so the sheet can't be a route
/// (`showModalBottomSheet` needs a Navigator ancestor) — it's drawn in a
/// Stack here instead, and needs no keyboard since PinPad is on-screen.
///
/// Wrong PINs share the login screens' limiter (5 misses → 5 min) so a
/// student can't brute-force the 4-digit parent code.
///
/// design_handoff FocusMode.dc.html · DESIGN_SPEC §4 "Focus mode".
class FocusModeOverlay extends ConsumerStatefulWidget {
  const FocusModeOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FocusModeOverlay> createState() => _FocusModeOverlayState();
}

class _FocusModeOverlayState extends ConsumerState<FocusModeOverlay> {
  static const PinAttemptLimiter _limiter = PinAttemptLimiter('focus');

  bool _sheetOpen = false;
  String _pin = '';
  bool _wrongPin = false;
  bool _checking = false;
  Duration? _lockedFor;

  Future<void> _openSheet() async {
    final Duration? locked = await _limiter.lockRemaining();
    if (!mounted) return;
    setState(() {
      _sheetOpen = true;
      _pin = '';
      _wrongPin = false;
      _lockedFor = locked;
    });
  }

  void _closeSheet() => setState(() {
        _sheetOpen = false;
        _pin = '';
        _wrongPin = false;
      });

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onDigit(String digit) async {
    if (_checking || _lockedFor != null || _pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _wrongPin = false;
    });
    if (_pin.length < 4) return;

    setState(() => _checking = true);
    final bool ok = await ref
        .read(focusLockControllerProvider.notifier)
        .unlockWithPin(_pin);
    final Duration? locked;
    if (ok) {
      await _limiter.reset();
      locked = null;
    } else {
      locked = await _limiter.recordFailure();
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _pin = '';
      _wrongPin = !ok;
      _lockedFor = locked;
      if (ok) _sheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(focusUnlockRequestProvider, (_, __) => _openSheet());
    final FocusLockState focus = ref.watch(focusLockControllerProvider);
    if (!focus.isActive) return widget.child;

    final DateTime until = focus.activeUntil!;
    final String untilLabel =
        FocusWindow.formatMinute(until.hour * 60 + until.minute);
    final bool showGuidedAccessHint = Platform.isIOS && !focus.isLocked;

    return Stack(
      children: [
        Column(
          children: [
            FocusModeBar(
              untilLabel: untilLabel,
              onUnlock: _sheetOpen ? _closeSheet : _openSheet,
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: widget.child,
              ),
            ),
          ],
        ),
        if (_sheetOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeSheet,
              child: const ColoredBox(color: DirasstyColors.scrim),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _UnlockSheet(
              pin: _pin,
              wrongPin: _wrongPin,
              lockedFor: _lockedFor,
              enabled: !_checking && _lockedFor == null,
              showGuidedAccessHint: showGuidedAccessHint,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
          ),
        ],
      ],
    );
  }
}

class _UnlockSheet extends StatelessWidget {
  const _UnlockSheet({
    required this.pin,
    required this.wrongPin,
    required this.lockedFor,
    required this.enabled,
    required this.showGuidedAccessHint,
    required this.onDigit,
    required this.onBackspace,
  });

  final String pin;
  final bool wrongPin;
  final Duration? lockedFor;
  final bool enabled;
  final bool showGuidedAccessHint;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final MediaQueryData media = MediaQuery.of(context);
    final String? error = lockedFor != null
        ? l10n.pinLocked((lockedFor!.inSeconds / 60).ceil())
        : (wrongPin ? l10n.errIncorrectCode : null);

    return Material(
      color: DirasstyColors.background,
      elevation: 12,
      shadowColor: DirasstyColors.ink.withValues(alpha: 0.3),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(DirasstySpace.xl, DirasstySpace.md,
              DirasstySpace.xl, DirasstySpace.xxl + media.padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DirasstyColors.inactiveBar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DirasstySpace.lg),
              Text(l10n.parentCode, style: type.titleSmall),
              const SizedBox(height: DirasstySpace.xs),
              Text(l10n.parentCodeBody,
                  style: type.bodySmall.copyWith(color: DirasstyColors.textMuted)),
              const SizedBox(height: DirasstySpace.lg),
              PinBoxes(value: pin, hasError: error != null),
              if (error != null) ...[
                const SizedBox(height: DirasstySpace.sm),
                Text(
                  error,
                  style: type.label.copyWith(
                      color: DirasstyColors.error, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: DirasstySpace.lg),
              PinPad(
                onDigit: onDigit,
                onBackspace: onBackspace,
                enabled: enabled,
                backspaceLabel: l10n.backspace,
              ),
              if (showGuidedAccessHint) ...[
                const SizedBox(height: DirasstySpace.lg),
                Container(
                  padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
                  decoration: const BoxDecoration(
                    color: DirasstyColors.tealTint,
                    borderRadius: DirasstyRadius.smallR,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: DirasstyColors.teal),
                      const SizedBox(width: DirasstySpace.sm),
                      Expanded(
                        child: Text(
                          l10n.guidedAccessHint,
                          style: type.label.copyWith(
                              color: DirasstyColors.text,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
