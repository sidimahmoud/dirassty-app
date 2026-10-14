import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

enum DirasstyButtonVariant {
  /// Teal fill, white text — the default call to action.
  primary,

  /// White fill, 1.5 px teal border, teal text.
  secondary,

  /// Ink fill, white text — parent space and "Continuer" after feedback.
  ink,

  /// Gold fill, ink text (never white on gold) — rewards and subscribe.
  gold,

  /// White fill, 1.5 px line border, ink text.
  quiet,

  /// Error fill, white text — destructive actions.
  danger,
}

/// Full-width 52 px button (44 when [compact]), radius 12, text 16/700,
/// optional 18 px leading icon. [loading] swaps the label for a spinner
/// without changing the button's size; a null [onPressed] disables it.
///
/// DESIGN_SPEC.md §2 "DirasstyButton".
class DirasstyButton extends StatelessWidget {
  const DirasstyButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = DirasstyButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.compact = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DirasstyButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool compact;

  /// Full width (default) or shrink-wrapped to its content.
  final bool expand;

  bool get _enabled => onPressed != null && !loading;

  ({Color bg, Color fg, BorderSide? side}) get _colors => switch (variant) {
        DirasstyButtonVariant.primary => (
            bg: DirasstyColors.teal,
            fg: Colors.white,
            side: null
          ),
        DirasstyButtonVariant.secondary => (
            bg: DirasstyColors.surface,
            fg: DirasstyColors.teal,
            side: const BorderSide(color: DirasstyColors.teal, width: 1.5),
          ),
        DirasstyButtonVariant.ink => (
            bg: DirasstyColors.ink,
            fg: Colors.white,
            side: null
          ),
        DirasstyButtonVariant.gold => (
            bg: DirasstyColors.gold,
            fg: DirasstyColors.ink,
            side: null
          ),
        DirasstyButtonVariant.quiet => (
            bg: DirasstyColors.surface,
            fg: DirasstyColors.ink,
            side: const BorderSide(color: DirasstyColors.line, width: 1.5),
          ),
        DirasstyButtonVariant.danger => (
            bg: DirasstyColors.error,
            fg: Colors.white,
            side: null
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    // Loading keeps the variant's own colors (only the label changes);
    // a truly disabled button goes grey.
    final bool greyedOut = onPressed == null && !loading;
    final Color bg = greyedOut ? DirasstyColors.disabledFill : colors.bg;
    final Color fg = greyedOut ? DirasstyColors.textMuted : colors.fg;
    final BorderSide? side = greyedOut ? null : colors.side;

    final Widget content = loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: DirasstySize.iconButton, color: fg),
                const SizedBox(width: DirasstySpace.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.dirasstyType.button.copyWith(color: fg),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: loading ? label : null,
      excludeSemantics: loading,
      // A minimum, not a fixed height: at large text sizes the button
      // grows instead of clipping its label (DESIGN_SPEC §7).
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: expand ? double.infinity : 0,
          minHeight: compact ? DirasstySize.buttonCompact : DirasstySize.button,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: DirasstyRadius.cardR,
            side: side ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: DirasstySpace.lg,
                vertical: DirasstySpace.xs,
              ),
              child: Center(heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
