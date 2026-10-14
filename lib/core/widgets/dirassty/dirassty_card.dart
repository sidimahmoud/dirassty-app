import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

enum DirasstyCardVariant {
  /// Plain card: white with a 1 px line border, no shadow.
  bordered,

  /// Hero/highlighted card: white with the level-2 shadow, no border.
  shadow,
}

/// White card, radius 12, padding 16 by default. Tappable when [onTap] is
/// set. DESIGN_SPEC.md §1 "Shadows" / §2.
class DirasstyCard extends StatelessWidget {
  const DirasstyCard({
    required this.child,
    super.key,
    this.variant = DirasstyCardVariant.bordered,
    this.padding = const EdgeInsetsDirectional.all(DirasstySpace.lg),
    this.color = DirasstyColors.surface,
    this.onTap,
  });

  final Widget child;
  final DirasstyCardVariant variant;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool bordered = variant == DirasstyCardVariant.bordered;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: DirasstyRadius.cardR,
        border: bordered ? Border.all(color: DirasstyColors.line) : null,
        boxShadow: bordered ? null : DirasstyShadow.level2,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: DirasstyRadius.cardR,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// One metric: value 24/800 (teal when [emphasize]), label 12/600 muted,
/// padding 16. [activeDays] switches to the "active days" variant with 7
/// mini bars under the value (teal active, grey inactive).
///
/// DESIGN_SPEC.md §2 "StatTile".
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    super.key,
    this.emphasize = false,
    this.activeDays,
  });

  final String value;
  final String label;
  final bool emphasize;

  /// Exactly 7 entries, oldest first.
  final List<bool>? activeDays;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: type.statValue.copyWith(
              color: emphasize ? DirasstyColors.teal : DirasstyColors.text,
            ),
          ),
          if (activeDays != null) ...[
            const SizedBox(height: DirasstySpace.xs),
            Row(
              children: [
                for (int i = 0; i < activeDays!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: activeDays![i]
                            ? DirasstyColors.teal
                            : DirasstyColors.inactiveBar,
                        borderRadius: DirasstyRadius.pillR,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: DirasstySpace.xs),
          Text(label, style: type.label),
        ],
      ),
    );
  }
}
