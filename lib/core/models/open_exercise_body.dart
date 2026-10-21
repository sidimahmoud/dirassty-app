import 'package:flutter/foundation.dart';

import 'diagram_spec.dart';
import 'difficulty.dart';

/// An open-ended (free-text), AI-corrected exercise. Ported from
/// `OpenExerciseBody` in packages/shared/src/types — the body of a
/// `content` row where `type = 'open_exercise'`, or the raw JSON returned
/// by `/api/generate-similar-exercise` (which isn't persisted to `content`
/// at all — see ExerciseRepository.generateSimilarExercise).
@immutable
class OpenExerciseBody {
  const OpenExerciseBody({
    required this.question,
    required this.hint,
    required this.solution,
    required this.topic,
    required this.difficulty,
    this.diagram,
  });

  factory OpenExerciseBody.fromJson(Map<String, dynamic> json) {
    return OpenExerciseBody(
      // Only question + solution are required; the web's manual form
      // omits empty hint/topic.
      question: json['question'] as String,
      hint: json['hint'] as String? ?? '',
      // Absent for AI follow-ups (kept server-side, see generated_token).
      solution: json['solution'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      difficulty: Difficulty.fromDb(json['difficulty'] as String? ?? ''),
      diagram: DiagramSpec.tryParse(json['diagram'] as Map<String, dynamic>?),
    );
  }

  final String question;

  /// Revealed after the student submits a draft answer, before the final
  /// AI-corrected submission — see OpenPracticeController.
  final String hint;

  /// The full worked solution used by the AI to grade the student's
  /// answer — never shown directly, only `correct_solution` on the
  /// [OpenExerciseCorrection] is.
  final String solution;
  final String topic;
  final Difficulty difficulty;

  /// Only present when the question genuinely needs a visual — see
  /// [DiagramSpec]'s doc comment.
  final DiagramSpec? diagram;
}
