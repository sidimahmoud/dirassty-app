import 'package:flutter/material.dart';

import '../../../../core/text/math_format.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';

/// Building blocks shared by the lesson steps (design_handoff
/// LessonConcept / WorkedExample / RevisionSheet).

/// A formula on ivory, centered, 22/800. Math is always laid out LTR,
/// even in Arabic (DESIGN_SPEC Phase 0 rule 8).
class FormulaBox extends StatelessWidget {
  const FormulaBox({required this.text, super.key, this.compact = false});

  final String text;

  /// Smaller inline variant (16/700, start-aligned) for worked-example
  /// steps.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        padding: compact
            ? const EdgeInsets.symmetric(
                horizontal: DirasstySpace.md, vertical: 10)
            : const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DirasstyColors.ivory,
          borderRadius: compact ? DirasstyRadius.smallR : DirasstyRadius.cardR,
        ),
        child: Text(
          cleanMathForDisplay(text),
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: (compact
                  ? type.subheading
                  : type.titleSmall.copyWith(fontSize: 22))
              .copyWith(fontFamily: 'Inter'),
        ),
      ),
    );
  }
}

/// White bordered card with an icon + bold label header — "Dans la vraie
/// vie", "Vérifie ta compréhension", revision sections.
class LessonCard extends StatelessWidget {
  const LessonCard({
    required this.children,
    super.key,
    this.icon,
    this.label,
    this.labelColor = DirasstyColors.ink,
    this.iconColor = DirasstyColors.teal,
  });

  final IconData? icon;
  final String? label;
  final Color labelColor;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DirasstyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: DirasstySpace.sm),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: context.dirasstyType.subheading
                        .copyWith(fontSize: 14, color: labelColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// A numbered step: 32 px ink circle, then its content.
class NumberedStep extends StatelessWidget {
  const NumberedStep({required this.number, required this.child, super.key});

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: DirasstyColors.ink, shape: BoxShape.circle),
          child: Text(
            '$number',
            style: context.dirasstyType.subheading.copyWith(
                fontSize: 14, color: Colors.white, fontFamily: 'Inter'),
          ),
        ),
        const SizedBox(width: DirasstySpace.md),
        Expanded(child: child),
      ],
    );
  }
}

/// goldTint callout with a warning icon — "Erreur fréquente".
class GoldCallout extends StatelessWidget {
  const GoldCallout({required this.title, required this.text, super.key});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: const BoxDecoration(
          color: DirasstyColors.goldTint, borderRadius: DirasstyRadius.cardR),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: DirasstyColors.goldStroke, size: 20),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '$title : ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: DirasstyColors.ink)),
                  TextSpan(text: cleanMathForDisplay(text)),
                ],
              ),
              style: type.bodySmall.copyWith(color: DirasstyColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Body text of a lesson (16, line height from the type scale), math
/// cleaned for display.
class LessonText extends StatelessWidget {
  const LessonText(this.text,
      {super.key, this.muted = false, this.small = false});

  final String text;
  final bool muted;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final TextStyle base = small ? type.bodySmall : type.body;
    return Text(
      cleanMathForDisplay(text),
      style: base.copyWith(
          color: muted ? DirasstyColors.textMuted : DirasstyColors.text,
          height: 1.55),
    );
  }
}
