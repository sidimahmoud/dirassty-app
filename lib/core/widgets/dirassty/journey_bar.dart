import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// Lesson progress: pills (Vidéo → Leçon → Exercices by default)
/// connected by 3 px lines. Done steps: teal tint with a check; the
/// active step: solid teal; upcoming: white with a line border. Order
/// follows reading direction, so it mirrors in Arabic.
///
/// DESIGN_SPEC.md §2 "JourneyBar".
class JourneyBar extends StatelessWidget {
  const JourneyBar({
    required this.steps,
    required this.currentIndex,
    this.activeIcon,
    super.key,
  });

  /// Already-localized step labels, e.g.
  /// `[l10n.journeyVideo, l10n.journeyLesson, l10n.journeyExercises]`.
  final List<String> steps;
  final int currentIndex;

  /// Optional glyph inside the active pill (▶ on the video step,
  /// LessonVideo.dc.html).
  final IconData? activeIcon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${currentIndex + 1}/${steps.length} · ${steps[currentIndex.clamp(0, steps.length - 1)]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsetsDirectional.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i <= currentIndex
                        ? DirasstyColors.teal
                        : DirasstyColors.inactiveBar,
                    borderRadius: DirasstyRadius.pillR,
                  ),
                ),
              ),
            _Pill(
              label: steps[i],
              icon: i == currentIndex ? activeIcon : null,
              state: i < currentIndex
                  ? _StepState.done
                  : i == currentIndex
                      ? _StepState.active
                      : _StepState.upcoming,
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.state, this.icon});

  final String label;
  final _StepState state;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = switch (state) {
      _StepState.done => (
          DirasstyColors.tealTint,
          DirasstyColors.tealDark,
          null
        ),
      _StepState.active => (DirasstyColors.teal, Colors.white, null),
      _StepState.upcoming => (
          DirasstyColors.surface,
          DirasstyColors.textMuted,
          DirasstyColors.line
        ),
    };
    return AnimatedContainer(
      duration: context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
      height: 32,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DirasstyRadius.pillR,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == _StepState.done || icon != null) ...[
            Icon(icon ?? Icons.check_rounded, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: context.dirasstyType.label.copyWith(
              color: fg,
              fontWeight: state == _StepState.upcoming
                  ? FontWeight.w600
                  : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
