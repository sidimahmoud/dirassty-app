import 'package:flutter/foundation.dart';

import '../i18n/app_lang.dart';

/// Ported from `SummaryBody` in packages/shared/src/types — the body of a
/// `content` row where `type = 'summary'`. A short revision card (a
/// handful of formulas/definitions/key facts, deliberately not a
/// re-explanation of the lesson) — see LessonSummarySheet for how it's
/// shown.
@immutable
class SummaryBody {
  const SummaryBody({required this.points, required this.lang});

  factory SummaryBody.fromJson(Map<String, dynamic> json) {
    return SummaryBody(
      points: (json['points'] as List<dynamic>).cast<String>(),
      lang: AppLang.fromDb(json['lang'] as String),
    );
  }

  final List<String> points;
  final AppLang lang;
}
