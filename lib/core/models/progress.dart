import 'package:flutter/foundation.dart';

import 'difficulty.dart';

/// Ported from `Progress` in packages/shared/src/types — one row per
/// (student, lesson, concept), updated by ProgressRepository.updateMastery.
@immutable
class Progress {
  const Progress({
    required this.studentId,
    required this.lessonId,
    required this.concept,
    required this.attempts,
    required this.correct,
    required this.mastery,
    required this.difficultyLevel,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      studentId: json['student_id'] as String,
      lessonId: json['lesson_id'] as String,
      concept: json['concept'] as String,
      attempts: json['attempts'] as int,
      correct: json['correct'] as int,
      mastery: (json['mastery'] as num).toDouble(),
      difficultyLevel: Difficulty.fromDb(json['difficulty_level'] as String),
    );
  }

  final String studentId;
  final String lessonId;
  final String concept;
  final int attempts;
  final int correct;
  final double mastery;
  final Difficulty difficultyLevel;
}
