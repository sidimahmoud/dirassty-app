import 'package:flutter/foundation.dart';

/// A small, fixed vocabulary of PRECISE diagrams a CustomPainter draws
/// (see DiagramView) — deliberately not an AI-generated image. An image
/// model can't reliably get a fraction split into exactly equal parts,
/// correctly-spaced number-line ticks, or legible Arabic labels; a wrong
/// diagram actively miseducates, which is worse than no diagram at all.
/// Mirrors `DiagramSpec` in packages/shared/src/types/index.ts — keep both
/// in sync. Optional everywhere it appears — a lesson/exercise without
/// one just never builds this widget.
sealed class DiagramSpec {
  const DiagramSpec();

  static DiagramSpec? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    return switch (json['kind'] as String?) {
      'number_line' => NumberLineDiagram.fromJson(json),
      'fraction_visual' => FractionVisualDiagram.fromJson(json),
      'bar_chart' => BarChartDiagram.fromJson(json),
      'geometry' => GeometryDiagram.tryFromJson(json),
      _ => null,
    };
  }
}

@immutable
class NumberLinePoint {
  const NumberLinePoint({
    required this.value,
    this.label,
    this.highlighted = false,
  });

  final double value;
  final String? label;
  final bool highlighted;

  factory NumberLinePoint.fromJson(Map<String, dynamic> json) {
    return NumberLinePoint(
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String?,
      highlighted: json['highlighted'] as bool? ?? false,
    );
  }
}

@immutable
class NumberLineRange {
  const NumberLineRange({required this.from, required this.to});

  final double from;
  final double to;

  factory NumberLineRange.fromJson(Map<String, dynamic> json) {
    return NumberLineRange(
      from: (json['from'] as num).toDouble(),
      to: (json['to'] as num).toDouble(),
    );
  }
}

final class NumberLineDiagram extends DiagramSpec {
  const NumberLineDiagram({
    required this.min,
    required this.max,
    required this.step,
    required this.points,
    this.range,
  });

  final double min;
  final double max;
  final double step;
  final List<NumberLinePoint> points;
  final NumberLineRange? range;

  factory NumberLineDiagram.fromJson(Map<String, dynamic> json) {
    return NumberLineDiagram(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      step: (json['step'] as num?)?.toDouble() ?? 1,
      points: (json['points'] as List<dynamic>? ?? [])
          .map((p) => NumberLinePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      range: json['range'] == null
          ? null
          : NumberLineRange.fromJson(json['range'] as Map<String, dynamic>),
    );
  }
}

@immutable
class FractionPart {
  const FractionPart({required this.numerator, required this.denominator});

  final int numerator;
  final int denominator;

  factory FractionPart.fromJson(Map<String, dynamic> json) {
    return FractionPart(
      numerator: json['numerator'] as int,
      denominator: json['denominator'] as int,
    );
  }
}

final class FractionVisualDiagram extends DiagramSpec {
  const FractionVisualDiagram({
    required this.shape,
    required this.numerator,
    required this.denominator,
    this.second,
  });

  /// 'circle' or 'rectangle'.
  final String shape;
  final int numerator;
  final int denominator;
  final FractionPart? second;

  factory FractionVisualDiagram.fromJson(Map<String, dynamic> json) {
    return FractionVisualDiagram(
      shape: json['shape'] as String? ?? 'circle',
      numerator: json['numerator'] as int,
      denominator: json['denominator'] as int,
      second: json['second'] == null
          ? null
          : FractionPart.fromJson(json['second'] as Map<String, dynamic>),
    );
  }
}

@immutable
class BarChartBar {
  const BarChartBar({required this.label, required this.value});

  final String label;
  final double value;

  factory BarChartBar.fromJson(Map<String, dynamic> json) {
    return BarChartBar(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
}

final class BarChartDiagram extends DiagramSpec {
  const BarChartDiagram({required this.bars, this.unit});

  final List<BarChartBar> bars;
  final String? unit;

  factory BarChartDiagram.fromJson(Map<String, dynamic> json) {
    return BarChartDiagram(
      bars: (json['bars'] as List<dynamic>? ?? [])
          .map((b) => BarChartBar.fromJson(b as Map<String, dynamic>))
          .toList(),
      unit: json['unit'] as String?,
    );
  }
}

// ── Geometry figure ─────────────────────────────────────────────────────

@immutable
class GeoPoint {
  const GeoPoint({required this.name, required this.x, required this.y});

  /// Label drawn next to the point ("A", "O", "M"…).
  final String name;

  /// Math coordinates (y up), in the figure's own units.
  final double x;
  final double y;
}

@immutable
class GeoSegment {
  const GeoSegment({
    required this.from,
    required this.to,
    this.label,
    this.dashed = false,
  });

  final String from;
  final String to;

  /// e.g. "5 cm", drawn at the middle of the segment.
  final String? label;
  final bool dashed;
}

@immutable
class GeoCircle {
  const GeoCircle({required this.center, required this.radius, this.label});

  final String center;
  final double radius;
  final String? label;
}

@immutable
class GeoAngle {
  const GeoAngle({
    required this.at,
    required this.from,
    required this.to,
    this.right = false,
    this.label,
  });

  /// Vertex, and the two points the angle's sides go to.
  final String at;
  final String from;
  final String to;

  /// Right angle → drawn as a small square.
  final bool right;
  final String? label;
}

/// A plane-geometry figure (triangle, quadrilateral, circle, coordinate
/// plane…): exact coordinates chosen by the AI to match the exercise's
/// data, drawn to scale by DiagramView. Unknown point names are skipped,
/// and an invalid spec parses to null (no figure rather than a wrong one).
final class GeometryDiagram extends DiagramSpec {
  const GeometryDiagram({
    required this.points,
    this.segments = const [],
    this.circles = const [],
    this.angles = const [],
    this.showGrid = false,
  });

  final List<GeoPoint> points;
  final List<GeoSegment> segments;
  final List<GeoCircle> circles;
  final List<GeoAngle> angles;

  /// Coordinate plane (axes + unit grid), for "repère" exercises.
  final bool showGrid;

  GeoPoint? point(String name) {
    for (final GeoPoint p in points) {
      if (p.name == name) return p;
    }
    return null;
  }

  static double? _num(Object? v) {
    final double? d = (v as num?)?.toDouble();
    return d != null && d.isFinite ? d : null;
  }

  static GeometryDiagram? tryFromJson(Map<String, dynamic> json) {
    try {
      final List<GeoPoint> points = [
        for (final dynamic p
            in (json['points'] as List<dynamic>? ?? []).take(30))
          if (p is Map<String, dynamic> &&
              p['name'] is String &&
              _num(p['x']) != null &&
              _num(p['y']) != null)
            GeoPoint(
              name: p['name'] as String,
              x: _num(p['x'])!,
              y: _num(p['y'])!,
            ),
      ];
      if (points.isEmpty) return null;
      final Set<String> names = {for (final GeoPoint p in points) p.name};
      bool known(Object? n) => n is String && names.contains(n);
      return GeometryDiagram(
        points: points,
        segments: [
          for (final dynamic s
              in (json['segments'] as List<dynamic>? ?? []).take(40))
            if (s is Map<String, dynamic> && known(s['from']) && known(s['to']))
              GeoSegment(
                from: s['from'] as String,
                to: s['to'] as String,
                label: s['label'] as String?,
                dashed: s['dashed'] as bool? ?? false,
              ),
        ],
        circles: [
          for (final dynamic c
              in (json['circles'] as List<dynamic>? ?? []).take(6))
            if (c is Map<String, dynamic> &&
                known(c['center']) &&
                (_num(c['radius']) ?? 0) > 0)
              GeoCircle(
                center: c['center'] as String,
                radius: _num(c['radius'])!,
                label: c['label'] as String?,
              ),
        ],
        angles: [
          for (final dynamic a
              in (json['angles'] as List<dynamic>? ?? []).take(12))
            if (a is Map<String, dynamic> &&
                known(a['at']) &&
                known(a['from']) &&
                known(a['to']))
              GeoAngle(
                at: a['at'] as String,
                from: a['from'] as String,
                to: a['to'] as String,
                right: a['right'] as bool? ?? false,
                label: a['label'] as String?,
              ),
        ],
        showGrid: json['show_grid'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
