import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// Streak count: goldTint pill, filled gold flame (18) and the number
/// 14/800. DESIGN_SPEC.md §2 "StreakBadge".
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.days, super.key, this.semanticLabel});

  final int days;

  /// e.g. `l10n.streakDays(days)` — read by screen readers instead of the
  /// bare number.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        height: 32,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: DirasstyColors.goldTint,
          borderRadius: DirasstyRadius.pillR,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 18, color: DirasstyColors.gold),
            const SizedBox(width: DirasstySpace.xs),
            Text(
              '$days',
              style: context.dirasstyType.subheading.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Level: 40 px gold square, radius 12, ink number.
/// DESIGN_SPEC.md §2 "LevelBadge".
class LevelBadge extends StatelessWidget {
  const LevelBadge(
      {required this.level, super.key, this.size = 40, this.semanticLabel});

  final int level;
  final double size;

  /// e.g. `l10n.level(level)`.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: DirasstyColors.gold,
          borderRadius: DirasstyRadius.cardR,
        ),
        child: Text(
          '$level',
          style: context.dirasstyType.heading.copyWith(
            color: DirasstyColors.ink,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

/// Round tinted badge holding an icon — used by empty/error states and
/// dialogs.
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    super.key,
    this.size = 64,
    this.background = DirasstyColors.tealTint,
    this.foreground = DirasstyColors.teal,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: size * 0.44),
    );
  }
}
