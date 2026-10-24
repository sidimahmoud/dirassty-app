import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import 'auth_scaffold.dart';

/// Tappable PIN boxes on a long form (Register, Claim invite): tapping
/// opens [showPinEntrySheet] with the custom keypad — the PIN never goes
/// through the system keyboard.
class PinField extends StatelessWidget {
  const PinField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.hint,
    this.errorText,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldLabel(label: label),
        const SizedBox(height: DirasstySpace.sm),
        Semantics(
          button: true,
          label: label,
          child: PinBoxes(
            value: value,
            hasError: errorText != null,
            onTap: () async {
              final String? pin =
                  await showPinEntrySheet(context, title: label);
              if (pin != null) onChanged(pin);
            },
          ),
        ),
        if (errorText != null || hint != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText ?? hint!,
            style: errorText != null
                ? type.label.copyWith(color: DirasstyColors.error)
                : type.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet with [PinBoxes] + [PinPad]; returns the 4 digits once
/// the last one is typed (null if dismissed).
Future<String?> showPinEntrySheet(
  BuildContext context, {
  required String title,
}) {
  return showDirasstyBottomSheet<String>(
    context,
    builder: (sheetContext) => _PinSheet(title: title),
  );
}

class _PinSheet extends StatefulWidget {
  const _PinSheet({required this.title});

  final String title;

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted) Navigator.of(context).pop(_pin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: context.dirasstyType.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DirasstySpace.xl),
        PinBoxes(value: _pin),
        const SizedBox(height: DirasstySpace.xl),
        PinPad(
          onDigit: _onDigit,
          onBackspace: () {
            if (_pin.isNotEmpty) {
              setState(() => _pin = _pin.substring(0, _pin.length - 1));
            }
          },
          backspaceLabel: l10n.backspace,
        ),
      ],
    );
  }
}

/// The WhatsApp-code step: 6 digit boxes fed by the keypad, auto-submit
/// on the 6th digit, 60 s resend countdown, "Modifier le numéro".
///
/// Getting the code in without typing: the WhatsApp message has a
/// "Copier le code" button. Back in the app, Android fills it in by itself
/// (the clipboard is read when the app comes back to the foreground); iOS
/// asks before any app reads the clipboard, so there it's one tap on
/// "Coller le code" (also always available, plus long-press on the boxes). Used by registration (parent always,
/// student when a phone was given).
///
/// design_handoff VerifyCode.dc.html · DESIGN_SPEC §4 "Verify code".
class VerifyCodeView extends StatefulWidget {
  const VerifyCodeView({
    required this.phoneDisplay,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
    required this.resendSecondsLeft,
    required this.loading,
    super.key,
    this.errorText,
  });

  /// "+222 22 45 67 89".
  final String phoneDisplay;
  final Future<void> Function(String code) onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;
  final int resendSecondsLeft;
  final bool loading;
  final String? errorText;

  @override
  State<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<VerifyCodeView>
    with WidgetsBindingObserver {
  String _code = '';

  /// Android: what the clipboard held when this screen opened, so an old
  /// copied code is never auto-submitted — only one copied since.
  String? _clipboardAtStart;

  /// Silent clipboard reads only where they don't trigger a system prompt.
  static bool get _canAutoPaste =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_canAutoPaste) {
      Clipboard.getData(Clipboard.kTextPlain)
          .then((data) => _clipboardAtStart = data?.text ?? '')
          .catchError((_) => _clipboardAtStart = '');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _canAutoPaste) {
      _paste(onlyIfNew: true);
    }
  }

  @override
  void didUpdateWidget(VerifyCodeView old) {
    super.didUpdateWidget(old);
    // A failed attempt clears the boxes so the next code starts fresh.
    if (widget.errorText != null && old.errorText != widget.errorText) {
      setState(() => _code = '');
    }
  }

  void _setCode(String code) {
    setState(() => _code = code);
    if (code.length == 6 && !widget.loading) widget.onVerify(code);
  }

  /// Fills (and submits) the 6-digit code found in the clipboard — the
  /// bare code from the "Copier le code" button, or a whole copied message.
  Future<void> _paste({bool onlyIfNew = false}) async {
    if (widget.loading) return;
    String text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    } catch (_) {
      return; // Clipboard unavailable: nothing to paste.
    }
    if (onlyIfNew && (_clipboardAtStart == null || text == _clipboardAtStart)) {
      return;
    }
    final String? code =
        RegExp(r'(?<!\d)\d{6}(?!\d)').firstMatch(text)?.group(0);
    if (code == null || !mounted) return;
    _clipboardAtStart = text;
    _setCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final int s = widget.resendSecondsLeft;
    final String countdown =
        '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

    return AuthScaffold(
      onBack: widget.onChangeNumber,
      bottom: [
        PinPad(
          onDigit: (d) {
            if (_code.length < 6) _setCode(_code + d);
          },
          onBackspace: () {
            if (_code.isNotEmpty) {
              setState(() => _code = _code.substring(0, _code.length - 1));
            }
          },
          enabled: !widget.loading,
          backspaceLabel: l10n.backspace,
        ),
        DirasstyButton(
          label: l10n.verify,
          loading: widget.loading,
          onPressed: _code.length == 6 ? () => widget.onVerify(_code) : null,
        ),
      ],
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconBadge(icon: Icons.chat_rounded, size: 56),
        ),
        AuthHeading(
          title: l10n.verifyTitle,
          body: l10n.verifyBody(widget.phoneDisplay),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tooltip(
              message: l10n.pasteCodeHint,
              child: GestureDetector(
                onLongPress: _paste,
                child: PinBoxes(
                  value: _code,
                  length: 6,
                  obscure: false,
                  hasError: widget.errorText != null,
                ),
              ),
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: DirasstySpace.sm),
              Text(
                widget.errorText!,
                style: type.label.copyWith(color: DirasstyColors.error),
              ),
            ],
            const SizedBox(height: DirasstySpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: widget.loading ? null : _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(l10n.pasteCode),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: s > 0
                      ? Text(l10n.resendIn(countdown), style: type.label)
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            style:
                                TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: widget.onResend,
                            child: Text(l10n.resendCode),
                          ),
                        ),
                ),
                TextButton(
                  onPressed: widget.onChangeNumber,
                  child: Text(l10n.changeNumber),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// "+222 22 45 67 89" from a local number, wrapped in LTR isolates so
/// it reads correctly inside an Arabic sentence (DESIGN_SPEC §7 numbers).
String formatMauritanianPhone(String local) {
  final String d = local.replaceAll(RegExp(r'\D'), '');
  final StringBuffer out = StringBuffer('\u2066+222 ');
  for (int i = 0; i < d.length; i++) {
    if (i > 0 && i % 2 == 0) out.write(' ');
    out.write(d[i]);
  }
  out.write('\u2069');
  return out.toString();
}
