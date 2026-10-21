import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// Circular mastery indicator. Starts at 12 o'clock and fills clockwise
/// in LTR, counter-clockwise in RTL; `track` background. Shows the
/// percentage (12/800) centered unless [showLabel] is false. Animates to
/// a new [value] over 400 ms (instantly with reduce-motion on).
///
/// DESIGN_SPEC.md §2 "SubjectCard" (52 px, stroke 5) and subject header
/// (80 px).
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    required this.value,
    super.key,
    this.size = 52,
    this.stroke = 5,
    this.color = DirasstyColors.teal,
    this.showLabel = true,
  });

  /// 0–1.
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double clamped = value.clamp(0, 1).toDouble();
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: clamped),
        duration:
            context.reduceMotion ? Duration.zero : DirasstyMotion.progress,
        curve: DirasstyMotion.curve,
        builder: (context, v, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter:
                _RingPainter(value: v, stroke: stroke, color: color, rtl: rtl),
            child: showLabel
                ? Center(
                    child: Text(
                      '${(v * 100).round()}%',
                      style: context.dirasstyType.label.copyWith(
                        color: DirasstyColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: size >= 72 ? 18 : (size < 48 ? 10.5 : 12),
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.rtl,
  });

  final double value;
  final double stroke;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = DirasstyColors.track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (value <= 0) return;
    final Paint fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final double sweep = 2 * math.pi * value * (rtl ? -1 : 1);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.rtl != rtl ||
      old.stroke != stroke;
}

/// Linear progress: 8 high, rounded, `track` background, teal fill (pass
/// ink for alternate subjects). Animates to a new value over 400 ms.
/// Fills from the start edge, so it mirrors in RTL.
///
/// DESIGN_SPEC.md §2 "ProgressBar".
class DirasstyProgressBar extends StatelessWidget {
  const DirasstyProgressBar({
    required this.value,
    super.key,
    this.color = DirasstyColors.teal,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 1).toDouble();
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: DirasstyRadius.pillR,
        child: Container(
          height: height,
          color: DirasstyColors.track,
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: clamped),
            duration:
                context.reduceMotion ? Duration.zero : DirasstyMotion.progress,
            curve: DirasstyMotion.curve,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: DirasstyRadius.pillR,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [DirasstyProgressBar] in gold — XP toward the next level.
/// DESIGN_SPEC.md §2 "XpBar".
class XpBar extends StatelessWidget {
  const XpBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) =>
      DirasstyProgressBar(value: value, color: DirasstyColors.gold);
}

/// Subject grid card: the subject icon tile and a compact 40 px
/// [MasteryRing] on top, then the name on one full-width line (15/700,
/// scales down rather than wrapping) and the lesson count (12 muted).
/// White, 1 px line border, padding 14. Ring colors alternate teal/ink
/// across the grid — the caller passes [ringColor].
///
/// DESIGN_SPEC.md §2 "SubjectCard".
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    required this.name,
    required this.lessonsLabel,
    required this.mastery,
    super.key,
    this.icon,
    this.ringColor = DirasstyColors.teal,
    this.onTap,
  });

  final String name;

  /// Already localized, e.g. `l10n.lessonsCount(12)`.
  final String lessonsLabel;
  final double mastery;

  /// The subject's emoji glyph (Subject.icon), shown in a tinted tile.
  final String? icon;
  final Color ringColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final Color tint = ringColor == DirasstyColors.teal
        ? DirasstyColors.tealTint
        : DirasstyColors.track;
    // Stacked layout: icon + compact ring on top, then the name on its own
    // full-width line — a side-by-side ring left too little room, so names
    // like "Mathématiques" wrapped onto two lines.
    return Material(
      color: DirasstyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: DirasstyRadius.cardR,
        side: BorderSide(color: DirasstyColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: DirasstyRadius.cardR,
                      ),
                      child: Text(icon!, style: const TextStyle(fontSize: 20)),
                    ),
                  const Spacer(),
                  MasteryRing(
                    value: mastery,
                    color: ringColor,
                    size: 40,
                    stroke: 4,
                  ),
                ],
              ),
              const SizedBox(height: DirasstySpace.md),
              // One line: shrinks a little for a long name rather than
              // wrapping; ellipsis only as a last resort.
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: type.subheading.copyWith(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lessonsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.label.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
