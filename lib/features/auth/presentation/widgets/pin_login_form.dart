import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/validation/validators.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/auth_providers.dart';
import 'auth_errors.dart';
import 'auth_scaffold.dart';

/// Shared body of the student and parent login screens: heading, an
/// identity field ([identityField]), the PIN boxes fed by the custom
/// [PinPad], the submit button, and the 5-wrong-PINs lockout
/// ([PinAttemptLimiter]). The PIN never goes through the system keyboard.
///
/// design_handoff StudentLogin.dc.html / ParentLogin.dc.html.
class PinLoginForm extends ConsumerStatefulWidget {
  const PinLoginForm({
    required this.heading,
    required this.identityField,
    required this.identityFilled,
    required this.submitLabel,
    required this.wrongCredentialsMessage,
    required this.limiterScope,
    required this.onSubmit,
    required this.onForgotPin,
    super.key,
    this.footer,
    this.lockedHint,
  });

  final Widget heading;
  final Widget identityField;

  /// Whether the identity field has something in it — the button is
  /// enabled once this is true and 4 digits are in.
  final bool identityFilled;
  final String submitLabel;
  final String wrongCredentialsMessage;

  /// 'student' | 'parent'.
  final String limiterScope;

  /// Signs in with [pin] (identity read by the screen itself).
  final Future<void> Function(String pin) onSubmit;
  final VoidCallback onForgotPin;
  final Widget? footer;

  /// Extra line under the lock message ("Demande à ton parent").
  final String? lockedHint;

  @override
  ConsumerState<PinLoginForm> createState() => _PinLoginFormState();
}

class _PinLoginFormState extends ConsumerState<PinLoginForm> {
  String _pin = '';
  String? _error;
  Duration? _lockLeft;
  Timer? _lockTicker;

  PinAttemptLimiter get _limiter => PinAttemptLimiter(widget.limiterScope);

  @override
  void initState() {
    super.initState();
    _refreshLock();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  Future<void> _refreshLock() async {
    final Duration? left = await _limiter.lockRemaining();
    if (!mounted) return;
    setState(() => _lockLeft = left);
    _lockTicker?.cancel();
    if (left != null) {
      _lockTicker = Timer(left, () {
        if (mounted) _refreshLock();
      });
    }
  }

  void _onDigit(String d) {
    FocusScope.of(context).unfocus();
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (!isValidPin(_pin) || _lockLeft != null) return;
    await widget.onSubmit(_pin);
    if (!mounted) return;
    final AsyncValue<void> result = ref.read(authControllerProvider);
    if (!result.hasError) {
      await _limiter.reset();
      return;
    }
    final Duration? lock = await _limiter.recordFailure();
    if (!mounted) return;
    setState(() {
      _pin = '';
      _error = widget.wrongCredentialsMessage;
    });
    if (lock != null) await _refreshLock();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool loading = ref.watch(authControllerProvider).isLoading;
    final bool locked = _lockLeft != null;
    final bool canSubmit = widget.identityFilled && _pin.length == 4 && !locked;

    return AuthScaffold(
      children: [
        widget.heading,
        widget.identityField,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFieldLabel(
              label: l10n.pinCode,
              trailing: TextButton(
                  onPressed: widget.onForgotPin, child: Text(l10n.forgotPin)),
            ),
            const SizedBox(height: DirasstySpace.xs),
            PinBoxes(value: _pin, hasError: _error != null),
            if (locked || _error != null) ...[
              const SizedBox(height: DirasstySpace.sm),
              Text(
                locked
                    ? l10n.pinLocked((_lockLeft!.inSeconds / 60).ceil())
                    : _error!,
                style: type.label.copyWith(color: DirasstyColors.error),
              ),
              if (locked && widget.lockedHint != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: DirasstySpace.xs),
                  child: Text(widget.lockedHint!, style: type.label),
                ),
            ],
          ],
        ),
      ],
      bottom: [
        PinPad(
          onDigit: _onDigit,
          onBackspace: _onBackspace,
          enabled: !locked && !loading,
          backspaceLabel: l10n.backspace,
        ),
        DirasstyButton(
          label: widget.submitLabel,
          loading: loading,
          onPressed: canSubmit ? _submit : null,
        ),
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}
