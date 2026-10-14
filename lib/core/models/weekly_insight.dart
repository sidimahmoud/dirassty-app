import 'package:flutter/foundation.dart';

/// A cached row from the `weekly_insights` table (see
/// supabase/migrations/015_weekly_insights.sql) — one per student per
/// week, generated on demand by `/api/generate/weekly-insight` the first
/// time a parent opens that child's screen in a given week.
@immutable
class WeeklyInsight {
  const WeeklyInsight({
    required this.insightText,
    required this.suggestionText,
    required this.bestSubject,
    required this.weakestSubject,
  });

  factory WeeklyInsight.fromJson(Map<String, dynamic> json) {
    return WeeklyInsight(
      insightText: json['insight_text'] as String,
      suggestionText: json['suggestion_text'] as String,
      bestSubject: json['best_subject'] as String?,
      weakestSubject: json['weakest_subject'] as String?,
    );
  }

  final String insightText;
  final String suggestionText;
  final String? bestSubject;
  final String? weakestSubject;
}
