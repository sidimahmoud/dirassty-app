import 'package:flutter/foundation.dart';

import 'lesson.dart';

/// A chapter with its lessons, grouped client-side from the flat
/// [CurriculumLesson] list — mirrors `getChapters` in
/// packages/shared/src/api/curriculum.ts, which builds this same shape
/// from `getCurriculum`'s flat rows rather than a dedicated chapters query.
@immutable
class Chapter {
  const Chapter({
    required this.num,
    required this.title,
    required this.lessons,
  });

  final int num;
  final String title;
  final List<CurriculumLesson> lessons;

  /// Groups a flat, already-sorted lesson list into chapters, preserving
  /// first-seen order (the query it's built from is ordered by chapter
  /// num, then lesson num).
  static List<Chapter> groupFrom(List<CurriculumLesson> lessons) {
    final Map<int, List<CurriculumLesson>> byChapter = {};
    final Map<int, String> titleByChapter = {};
    for (final CurriculumLesson lesson in lessons) {
      byChapter.putIfAbsent(lesson.chapterNum, () => []).add(lesson);
      titleByChapter[lesson.chapterNum] = lesson.chapterTitle;
    }
    return byChapter.entries
        .map(
          (e) => Chapter(
            num: e.key,
            title: titleByChapter[e.key]!,
            lessons: e.value,
          ),
        )
        .toList();
  }
}
