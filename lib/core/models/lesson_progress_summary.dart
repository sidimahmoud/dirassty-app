import 'package:flutter/foundation.dart';

/// One lesson's status for a single student — the two independent facts a
/// parent asks about ("did they even open this?" vs "did they actually
/// practice it?") rather than the single blended mastery % the student's
/// own subject screen shows (see ProgressRepository.getLessonMasteryMap,
/// which folds a viewed-only lesson into a mastery floor instead of
/// keeping the two facts separate — right for a motivational student-
/// facing number, wrong for a parent wanting the real breakdown).
@immutable
class LessonProgressSummary {
  const LessonProgressSummary({
    required this.viewed,
    required this.exercisesDone,
    required this.attempts,
    required this.mastery,
  });

  static const LessonProgressSummary none = LessonProgressSummary(
    viewed: false,
    exercisesDone: false,
    attempts: 0,
    mastery: 0,
  );

  /// Whether the student has opened the lesson's explanation at least
  /// once (see ProgressRepository.markLessonViewed).
  final bool viewed;

  /// Whether at least one exercise attempt is recorded for this lesson.
  final bool exercisesDone;
  final int attempts;

  /// 0–1. Only meaningful when [exercisesDone] is true.
  final double mastery;
}
