import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// The row of boxes a PIN (4) or WhatsApp code (6) is shown in, driven by
/// [value] — pair it with [PinPad] (PINs) or a hidden system field
/// (codes, where paste/autofill matters). Boxes are 56 high, spaced 12
/// (10 for 6), always laid out LTR.
///
/// [obscure] boxes show a 14 px ink dot per digit; otherwise the digit
/// itself at 22/800. The next box to fill has a teal border.
///
/// DESIGN_SPEC.md §2 "PinBoxes".
class PinBoxes extends StatelessWidget {
  const PinBoxes({
    required this.value,
    super.key,
    this.length = 4,
    this.obscure = true,
    this.hasError = false,
    this.onTap,
  });

  final String value;
  final int length;
  final bool obscure;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double gap = length > 4 ? 10 : DirasstySpace.md;
    final int active = value.length.clamp(0, length - 1);
    final bool complete = value.length >= length;

    return Semantics(
      label: '${value.length}/$length',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (int i = 0; i < length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _Box(
                    char: i < value.length ? value[i] : null,
                    obscure: obscure,
                    active: !complete && i == active,
                    hasError: hasError,
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

class _Box extends StatelessWidget {
  const _Box({
    required this.char,
    required this.obscure,
    required this.active,
    required this.hasError,
  });

  final String? char;
  final bool obscure;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color border = hasError
        ? DirasstyColors.error
        : active
            ? DirasstyColors.teal
            : DirasstyColors.line;
    return AnimatedContainer(
      duration: DirasstyMotion.fast,
      height: DirasstySize.pinBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: border, width: active || hasError ? 2 : 1.5),
      ),
      child: char == null
          ? null
          : obscure
              ? Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: DirasstyColors.ink,
                    shape: BoxShape.circle,
                  ),
                )
              : Text(
                  char!,
                  style: context.dirasstyType.title.copyWith(fontSize: 22),
                ),
    );
  }
}

/// Custom 3×4 numeric keypad — never the system keyboard — for student
/// login, the parent code and focus unlock. Keys 56 high on white, digits
/// 24/600, gap 8; bottom-left empty, bottom-right backspace. Always LTR
/// (a keypad's digit order never mirrors), light haptic tick per press.
///
/// DESIGN_SPEC.md §2 "PinPad".
class PinPad extends StatelessWidget {
  const PinPad({
    required this.onDigit,
    required this.onBackspace,
    super.key,
    this.enabled = true,
    this.backspaceLabel = 'Backspace',
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  /// Screen-reader label for the backspace key.
  final String backspaceLabel;

  static const List<String> _keys = [
    '1', '2', '3', //
    '4', '5', '6',
    '7', '8', '9',
    '', '0', '<',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: DirasstySpace.sm),
            Row(
              children: [
                for (int col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: DirasstySpace.sm),
                  Expanded(child: _key(context, _keys[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String key) {
    if (key.isEmpty) return const SizedBox(height: DirasstySize.pinKey);
    final bool isBackspace = key == '<';
    return Semantics(
      button: true,
      label: isBackspace ? backspaceLabel : key,
      child: SizedBox(
        height: DirasstySize.pinKey,
        child: Material(
          color: isBackspace ? Colors.transparent : DirasstyColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: DirasstyRadius.cardR,
            side: isBackspace
                ? BorderSide.none
                : const BorderSide(color: DirasstyColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: !enabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    isBackspace ? onBackspace() : onDigit(key);
                  },
            child: Center(
              child: isBackspace
                  ? const Icon(
                      Icons.backspace_outlined,
                      color: DirasstyColors.ink,
                    )
                  : ExcludeSemantics(
                      child: Text(
                        key,
                        style: context.dirasstyType.title.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
