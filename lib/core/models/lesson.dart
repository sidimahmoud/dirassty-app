import 'package:flutter/foundation.dart';

import '../i18n/app_lang.dart';

/// Ported from `CurriculumLesson` in packages/shared/src/types — a flat
/// view of a lesson with its chapter/subject context, as returned by the
/// JOIN in CurriculumRepository.getChapters/getLessonById (mirrors
/// packages/shared/src/api/curriculum.ts's `flattenLesson`).
@immutable
class CurriculumLesson {
  const CurriculumLesson({
    required this.id,
    required this.country,
    required this.grade,
    required this.subjectKey,
    required this.subjectLang,
    required this.chapterNum,
    required this.chapterTitle,
    required this.lessonNum,
    required this.lessonTitle,
    required this.concepts,
    required this.isActive,
  });

  /// [row] is a single `lessons` row joined to `chapter:chapter_id` and
  /// `subject:subject_id` — see CurriculumRepository for the exact select.
  factory CurriculumLesson.fromJoinedJson(Map<String, dynamic> row) {
    final Map<String, dynamic> chapter = row['chapter'] as Map<String, dynamic>;
    final Map<String, dynamic> subject =
        chapter['subject'] as Map<String, dynamic>;
    return CurriculumLesson(
      id: row['id'] as String,
      country: subject['country'] as String,
      grade: subject['grade'] as int,
      subjectKey: subject['key'] as String,
      subjectLang: AppLang.fromDb(subject['lang'] as String),
      chapterNum: chapter['num'] as int,
      chapterTitle: chapter['title'] as String,
      lessonNum: row['num'] as int,
      lessonTitle: row['title'] as String,
      concepts: (row['concepts'] as List<dynamic>).cast<String>(),
      isActive: row['is_active'] as bool,
    );
  }

  final String id;
  final String country;
  final int grade;
  final String subjectKey;
  final AppLang subjectLang;
  final int chapterNum;
  final String chapterTitle;
  final int lessonNum;
  final String lessonTitle;
  final List<String> concepts;
  final bool isActive;
}
