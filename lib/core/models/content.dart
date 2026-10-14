import 'package:flutter/foundation.dart';

import 'difficulty.dart';
import 'exercise_body.dart';
import 'open_exercise_body.dart';

/// A `content` row of `type = 'exercise'` — the row `id` is kept alongside
/// the parsed [ExerciseBody] because ProgressRepository.updateMastery is
/// keyed by concept, not content id, but the QCM session still needs the
/// id for its per-answer recap list.
@immutable
class ExerciseContent {
  const ExerciseContent({
    required this.id,
    required this.difficulty,
    required this.body,
  });

  factory ExerciseContent.fromJson(Map<String, dynamic> json) {
    return ExerciseContent(
      id: json['id'] as String,
      difficulty: Difficulty.fromDb(json['difficulty'] as String? ?? ''),
      body: ExerciseBody.fromJson(json['body'] as Map<String, dynamic>),
    );
  }

  final String id;
  final Difficulty difficulty;
  final ExerciseBody body;
}

/// A `content` row of `type = 'open_exercise'`.
@immutable
class OpenExerciseContent {
  const OpenExerciseContent({required this.id, required this.body});

  factory OpenExerciseContent.fromJson(Map<String, dynamic> json) {
    return OpenExerciseContent(
      id: json['id'] as String,
      body: OpenExerciseBody.fromJson(json['body'] as Map<String, dynamic>),
    );
  }

  final String id;
  final OpenExerciseBody body;
}
