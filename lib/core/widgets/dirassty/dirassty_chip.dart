import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

enum DirasstyChipVariant {
  /// White, 1 px line border — filters, unselected choices.
  neutral,

  /// Ink fill, white text — the selected filter/choice.
  selected,

  /// Teal status: "Actif", "Abonnée".
  teal,

  /// Gold status: "Essai", "En vérification", "À venir".
  gold,

  /// Red status: "Expiré", "Refusé".
  red,
}

/// Pill chip, 32 high (28 when [dense]), text 12/700, optional leading
/// icon. Tappable when [onTap] is set.
///
/// DESIGN_SPEC.md §2 "DirasstyChip".
class DirasstyChip extends StatelessWidget {
  const DirasstyChip({
    required this.label,
    super.key,
    this.variant = DirasstyChipVariant.neutral,
    this.icon,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final DirasstyChipVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dense;

  ({Color bg, Color fg, Color? border}) get _colors => switch (variant) {
        DirasstyChipVariant.neutral => (
            bg: DirasstyColors.surface,
            fg: DirasstyColors.ink,
            border: DirasstyColors.line
          ),
        DirasstyChipVariant.selected => (
            bg: DirasstyColors.ink,
            fg: Colors.white,
            border: null
          ),
        DirasstyChipVariant.teal => (
            bg: DirasstyColors.tealTint,
            fg: DirasstyColors.tealDark,
            border: null
          ),
        DirasstyChipVariant.gold => (
            bg: DirasstyColors.goldTint,
            fg: DirasstyColors.ink,
            border: null
          ),
        DirasstyChipVariant.red => (
            bg: DirasstyColors.errorTint,
            fg: DirasstyColors.errorDark,
            border: null
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final Widget chip = Container(
      constraints: BoxConstraints(minHeight: dense ? 28 : 32),
      alignment: Alignment.center,
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: dense ? 10 : DirasstySpace.md),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: DirasstyRadius.pillR,
        border:
            colors.border == null ? null : Border.all(color: colors.border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.fg),
            const SizedBox(width: DirasstySpace.xs),
          ],
          Text(
            label,
            style: context.dirasstyType.label.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: variant == DirasstyChipVariant.selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: DirasstyRadius.pillR,
        // Keep a 44 pt touch target around the 32 px pill.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DirasstySize.minTouch),
          child: Center(widthFactor: 1, child: chip),
        ),
      ),
    );
  }
}
