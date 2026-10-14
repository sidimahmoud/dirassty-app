import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/diagram_spec.dart';
import '../theme/dirassty_theme.dart';

/// Renders one of the fixed diagram kinds precisely via CustomPainter —
/// see [DiagramSpec]'s doc comment for why this is deliberately not an
/// AI-generated image. Used from a lesson's worked examples and from
/// exercise questions, wherever their body carries a non-null `diagram`.
class DiagramView extends StatelessWidget {
  const DiagramView(
      {super.key, required this.spec, this.color = DirasstyColors.teal});

  final DiagramSpec spec;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double height = switch (spec) {
      NumberLineDiagram() => 110,
      FractionVisualDiagram() => 170,
      BarChartDiagram() => 190,
      GeometryDiagram() => 260,
    };

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: switch (spec) {
          NumberLineDiagram s => _NumberLinePainter(s, color),
          FractionVisualDiagram s => _FractionPainter(s, color),
          BarChartDiagram s => _BarChartPainter(s, color),
          GeometryDiagram s => _GeometryPainter(s, color),
        },
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter(this.spec, this.color);

  final NumberLineDiagram spec;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double marginH = 24;
    final double lineY = size.height * 0.45;
    final double left = marginH;
    final double right = size.width - marginH;
    final double span = spec.max - spec.min;
    if (span <= 0) return;

    double xFor(double value) =>
        left + (value - spec.min) / span * (right - left);

    final Paint linePaint = Paint()
      ..color = DirasstyColors.textMuted
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left, lineY), Offset(right, lineY), linePaint);

    // Arrowhead at the right end.
    final Path arrow = Path()
      ..moveTo(right, lineY)
      ..lineTo(right - 8, lineY - 5)
      ..moveTo(right, lineY)
      ..lineTo(right - 8, lineY + 5);
    canvas.drawPath(arrow, linePaint..style = PaintingStyle.stroke);

    // Shaded range, if any (e.g. for an inequality).
    if (spec.range != null) {
      final Paint rangePaint = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(xFor(spec.range!.from), lineY),
        Offset(xFor(spec.range!.to), lineY),
        rangePaint,
      );
    }

    // Ticks + numeric labels.
    final int step = spec.step <= 0 ? 1 : spec.step.round();
    for (num v = spec.min; v <= spec.max; v += step) {
      final double x = xFor(v.toDouble());
      canvas.drawLine(Offset(x, lineY - 5), Offset(x, lineY + 5), linePaint);
      _drawText(
        canvas,
        _trimNum(v.toDouble()),
        Offset(x, lineY + 22),
        DirasstyColors.textMuted,
        11,
      );
    }

    // Points on top of ticks — highlighted ones bigger and in accent color.
    for (final NumberLinePoint pt in spec.points) {
      final double x = xFor(pt.value);
      final double r = pt.highlighted ? 7 : 5;
      canvas.drawCircle(
        Offset(x, lineY),
        r,
        Paint()..color = pt.highlighted ? color : DirasstyColors.textMuted,
      );
      if (pt.label != null) {
        _drawText(
          canvas,
          pt.label!,
          Offset(x, lineY - 22),
          pt.highlighted ? color : DirasstyColors.textMuted,
          12,
          bold: pt.highlighted,
        );
      }
    }
  }

  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  bool shouldRepaint(covariant _NumberLinePainter oldDelegate) =>
      oldDelegate.spec != spec || oldDelegate.color != color;
}

class _FractionPainter extends CustomPainter {
  _FractionPainter(this.spec, this.color);

  final FractionVisualDiagram spec;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bool hasSecond = spec.second != null;
    final double slotW = hasSecond ? size.width / 2 : size.width;

    _drawOne(canvas, Rect.fromLTWH(0, 0, slotW, size.height), spec.numerator,
        spec.denominator);
    if (hasSecond) {
      _drawOne(
        canvas,
        Rect.fromLTWH(slotW, 0, slotW, size.height),
        spec.second!.numerator,
        spec.second!.denominator,
      );
    }
  }

  void _drawOne(Canvas canvas, Rect bounds, int numerator, int denominator) {
    if (denominator <= 0) return;
    final double side = bounds.height * 0.72;
    final Rect box = Rect.fromCenter(
      center: Offset(bounds.center.dx, bounds.center.dy - 8),
      width: side,
      height: side,
    );

    final Paint fillShaded = Paint()..color = color.withValues(alpha: 0.65);
    final Paint fillPlain = Paint()..color = DirasstyColors.surface;
    final Paint border = Paint()
      ..color = DirasstyColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (spec.shape == 'rectangle') {
      final double partW = box.width / denominator;
      for (int i = 0; i < denominator; i++) {
        final Rect part =
            Rect.fromLTWH(box.left + i * partW, box.top, partW, box.height);
        canvas.drawRect(part, i < numerator ? fillShaded : fillPlain);
        canvas.drawRect(part, border);
      }
    } else {
      final double radius = side / 2;
      final Offset center = box.center;
      const double startAngle = -1.5707963267948966; // -90deg, 12 o'clock
      final double sweep = 2 * 3.141592653589793 / denominator;
      for (int i = 0; i < denominator; i++) {
        final Path slice = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            startAngle + i * sweep,
            sweep,
            false,
          )
          ..close();
        canvas.drawPath(slice, i < numerator ? fillShaded : fillPlain);
        canvas.drawPath(slice, border);
      }
    }

    _drawText(
      canvas,
      "$numerator/$denominator",
      Offset(bounds.center.dx, bounds.bottom - 6),
      color,
      16,
      bold: true,
    );
  }

  @override
  bool shouldRepaint(covariant _FractionPainter oldDelegate) =>
      oldDelegate.spec != spec || oldDelegate.color != color;
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.spec, this.color);

  final BarChartDiagram spec;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (spec.bars.isEmpty) return;
    const double marginH = 16;
    const double bottomLabelH = 40;
    final double maxValue =
        spec.bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;

    final double chartH = size.height - bottomLabelH;
    final double slotW = (size.width - marginH * 2) / spec.bars.length;
    final double barW = slotW * 0.5;

    for (int i = 0; i < spec.bars.length; i++) {
      final BarChartBar bar = spec.bars[i];
      final double barH = (bar.value / maxValue) * (chartH - 24);
      final double slotCenter = marginH + slotW * i + slotW / 2;
      final Rect barRect = Rect.fromLTWH(
        slotCenter - barW / 2,
        chartH - barH,
        barW,
        barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: 0.75),
      );
      _drawText(
        canvas,
        _trimNum(bar.value) + (spec.unit != null ? " ${spec.unit}" : ""),
        Offset(slotCenter, chartH - barH - 12),
        DirasstyColors.textMuted,
        11,
      );
      _drawText(
        canvas,
        bar.label,
        Offset(slotCenter, chartH + 18),
        DirasstyColors.textMuted,
        11,
        bold: true,
      );
    }

    canvas.drawLine(
      Offset(marginH, chartH),
      Offset(size.width - marginH, chartH),
      Paint()
        ..color = DirasstyColors.textMuted
        ..strokeWidth = 1.5,
    );
  }

  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.spec != spec || oldDelegate.color != color;
}

void _drawText(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
  double fontSize, {
  bool bold = false,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Plane-geometry figure drawn to scale (one scale for x and y, so angles
/// and proportions are true): optional coordinate grid + axes, circles,
/// segments (dashed / with length labels), right-angle squares and angle
/// arcs, then the named points on top.
class _GeometryPainter extends CustomPainter {
  _GeometryPainter(this.spec, this.color);

  final GeometryDiagram spec;
  final Color color;

  static const double _pad = 30;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 2 * _pad || size.height <= 2 * _pad) return;

    // Bounds in figure units (circles and, on a grid, the origin included).
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    void grow(double x, double y) {
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    for (final GeoPoint p in spec.points) {
      grow(p.x, p.y);
    }
    for (final GeoCircle c in spec.circles) {
      final GeoPoint? o = spec.point(c.center);
      if (o == null) continue;
      grow(o.x - c.radius, o.y - c.radius);
      grow(o.x + c.radius, o.y + c.radius);
    }
    if (spec.showGrid) {
      grow(0, 0);
      minX = minX.floorToDouble() - 0.5;
      minY = minY.floorToDouble() - 0.5;
      maxX = maxX.ceilToDouble() + 0.5;
      maxY = maxY.ceilToDouble() + 0.5;
    }
    final double w = math.max(maxX - minX, 1e-6);
    final double h = math.max(maxY - minY, 1e-6);
    final double scale =
        math.min((size.width - 2 * _pad) / w, (size.height - 2 * _pad) / h);
    final double ox = (size.width - w * scale) / 2;
    final double oy = (size.height - h * scale) / 2;
    Offset map(double x, double y) => Offset(
        ox + (x - minX) * scale, size.height - (oy + (y - minY) * scale));
    Offset at(String name) {
      final GeoPoint p = spec.point(name)!;
      return map(p.x, p.y);
    }

    final Paint line = Paint()
      ..color = DirasstyColors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint accent = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    if (spec.showGrid) _paintGrid(canvas, size, minX, maxX, minY, maxY, map);

    for (final GeoCircle c in spec.circles) {
      canvas.drawCircle(
          at(c.center), c.radius * scale, accent..strokeWidth = 2);
      if (c.label != null) {
        final GeoPoint o = spec.point(c.center)!;
        _text(
            canvas,
            c.label!,
            map(o.x + c.radius * 0.71, o.y + c.radius * 0.71) +
                const Offset(6, -6),
            color: color);
      }
    }

    for (final GeoSegment sg in spec.segments) {
      final Offset a = at(sg.from), b = at(sg.to);
      if (sg.dashed) {
        _dashed(canvas, a, b, line..strokeWidth = 1.6);
        line.strokeWidth = 2;
      } else {
        canvas.drawLine(a, b, line);
      }
      if (sg.label != null && sg.label!.trim().isNotEmpty) {
        final Offset d = b - a;
        final double len = d.distance;
        if (len > 0) {
          final Offset normal = Offset(-d.dy / len, d.dx / len);
          final Offset centre = _centroid(map);
          final Offset mid = (a + b) / 2;
          // Put the length on the side away from the figure's centre.
          final Offset side = (mid + normal * 12 - centre).distance >=
                  (mid - normal * 12 - centre).distance
              ? normal
              : -normal;
          _text(canvas, sg.label!, mid + side * 13,
              color: DirasstyColors.textMuted, centred: true);
        }
      }
    }

    for (final GeoAngle an in spec.angles) {
      final Offset v = at(an.at);
      final Offset d1 = at(an.from) - v, d2 = at(an.to) - v;
      if (d1.distance == 0 || d2.distance == 0) continue;
      final Offset u1 = d1 / d1.distance, u2 = d2 / d2.distance;
      if (an.right) {
        const double k = 11;
        final Path sq = Path()
          ..moveTo(v.dx + u1.dx * k, v.dy + u1.dy * k)
          ..lineTo(v.dx + (u1.dx + u2.dx) * k, v.dy + (u1.dy + u2.dy) * k)
          ..lineTo(v.dx + u2.dx * k, v.dy + u2.dy * k);
        canvas.drawPath(sq, accent..strokeWidth = 1.6);
      } else {
        const double r = 20;
        final double a1 = math.atan2(u1.dy, u1.dx);
        double sweep = math.atan2(u2.dy, u2.dx) - a1;
        while (sweep > math.pi) {
          sweep -= 2 * math.pi;
        }
        while (sweep < -math.pi) {
          sweep += 2 * math.pi;
        }
        canvas.drawArc(Rect.fromCircle(center: v, radius: r), a1, sweep, false,
            accent..strokeWidth = 1.6);
        if (an.label != null && an.label!.trim().isNotEmpty) {
          final Offset bis = u1 + u2;
          final Offset dir =
              bis.distance == 0 ? Offset(-u1.dy, u1.dx) : bis / bis.distance;
          _text(canvas, an.label!, v + dir * 34, color: color, centred: true);
        }
      }
    }

    final Paint dot = Paint()..color = DirasstyColors.ink;
    final Offset centre = _centroid(map);
    for (final GeoPoint p in spec.points) {
      final Offset o = map(p.x, p.y);
      canvas.drawCircle(o, 3.5, dot);
      Offset dir = o - centre;
      dir = dir.distance < 1 ? const Offset(-0.7, -0.7) : dir / dir.distance;
      _text(canvas, p.name, o + dir * 14, bold: true, centred: true);
    }
  }

  Offset _centroid(Offset Function(double, double) map) {
    double sx = 0, sy = 0;
    for (final GeoPoint p in spec.points) {
      sx += p.x;
      sy += p.y;
    }
    return map(sx / spec.points.length, sy / spec.points.length);
  }

  void _paintGrid(Canvas canvas, Size size, double minX, double maxX,
      double minY, double maxY, Offset Function(double, double) map) {
    final int nx = (maxX - minX).floor(), ny = (maxY - minY).floor();
    if (nx > 40 || ny > 40) return;
    final Paint grid = Paint()
      ..color = DirasstyColors.line
      ..strokeWidth = 1;
    final Paint axis = Paint()
      ..color = DirasstyColors.textMuted
      ..strokeWidth = 1.4;
    final int labelStep = math.max(nx, ny) > 14 ? 2 : 1;
    for (int x = minX.ceil(); x <= maxX.floor(); x++) {
      canvas.drawLine(map(x.toDouble(), minY), map(x.toDouble(), maxY),
          x == 0 ? axis : grid);
      if (x != 0 && x % labelStep == 0) {
        _text(canvas, '$x', map(x.toDouble(), 0) + const Offset(0, 9),
            color: DirasstyColors.textMuted, centred: true, small: true);
      }
    }
    for (int y = minY.ceil(); y <= maxY.floor(); y++) {
      canvas.drawLine(map(minX, y.toDouble()), map(maxX, y.toDouble()),
          y == 0 ? axis : grid);
      if (y != 0 && y % labelStep == 0) {
        _text(canvas, '$y', map(0, y.toDouble()) + const Offset(-10, 0),
            color: DirasstyColors.textMuted, centred: true, small: true);
      }
    }
    _text(canvas, 'O', map(0, 0) + const Offset(-9, 9),
        color: DirasstyColors.textMuted, centred: true, small: true);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final Offset d = b - a;
    final double len = d.distance;
    if (len == 0) return;
    final Offset u = d / len;
    for (double t = 0; t < len; t += 10) {
      canvas.drawLine(a + u * t, a + u * math.min(t + 5, len), paint);
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {Color color = DirasstyColors.ink,
      bool bold = false,
      bool centred = false,
      bool small = false}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      // Math labels read left-to-right in both app languages.
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centred ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  bool shouldRepaint(_GeometryPainter oldDelegate) =>
      oldDelegate.spec != spec || oldDelegate.color != color;
}
