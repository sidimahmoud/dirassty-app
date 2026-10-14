import 'package:flutter/foundation.dart';

enum CorrectionScore {
  correct,
  partial,
  incorrect,

  /// The AI couldn't judge reliably (unreadable photo, low confidence) —
  /// shown as "retake / try again", never as right or wrong.
  undetermined;

  /// Reads the API's `overall` (correct / partially_correct / incorrect /
  /// undetermined), falling back to the legacy `score` field.
  static CorrectionScore fromJson(Map<String, dynamic> json) =>
      switch (json['overall'] as String? ?? json['score'] as String?) {
        'correct' => CorrectionScore.correct,
        'partially_correct' || 'partial' => CorrectionScore.partial,
        'undetermined' => CorrectionScore.undetermined,
        _ => CorrectionScore.incorrect,
      };
}

@immutable
class CorrectionMistake {
  const CorrectionMistake(
      {required this.step, required this.issue, required this.type});

  final String step;
  final String issue;

  /// reasoning | calculation | notation | missing
  final String type;
}

/// The AI's check of a student's solution — typed or photographed
/// (handwritten). `SolutionCheck` in packages/shared/src/lib/tutor.ts,
/// returned by `POST /api/correct-open-exercise`. Reasoning, calculation
/// and final answer are judged separately; an unreadable photo comes back
/// as [CorrectionScore.undetermined] + [retakePhoto].
@immutable
class OpenExerciseCorrection {
  const OpenExerciseCorrection({
    required this.score,
    required this.whatWasRight,
    required this.whatWasWrong,
    required this.correctSolution,
    required this.encouragement,
    this.readability = 'clear',
    this.imageIssues = const [],
    this.retakePhoto = false,
    this.transcription = '',
    this.method = 'unclear',
    this.reasoningCorrect,
    this.calculationCorrect,
    this.finalAnswerCorrect,
    this.correctSteps = const [],
    this.mistakes = const [],
    this.confidence = 1,
  });

  factory OpenExerciseCorrection.fromJson(Map<String, dynamic> json) {
    String s(String k) => json[k] as String? ?? '';
    return OpenExerciseCorrection(
      score: CorrectionScore.fromJson(json),
      whatWasRight: s('what_was_right'),
      whatWasWrong: s('what_was_wrong'),
      correctSolution: s('correct_solution'),
      encouragement: s('encouragement'),
      readability: json['readability'] as String? ?? 'clear',
      imageIssues:
          (json['image_issues'] as List<dynamic>?)?.cast<String>() ?? const [],
      retakePhoto: json['retake_photo'] as bool? ?? false,
      transcription: s('transcription'),
      method: json['method'] as String? ?? 'unclear',
      reasoningCorrect: json['reasoning_correct'] as bool?,
      calculationCorrect: json['calculation_correct'] as bool?,
      finalAnswerCorrect: json['final_answer_correct'] as bool?,
      correctSteps:
          (json['correct_steps'] as List<dynamic>?)?.cast<String>() ?? const [],
      mistakes: ((json['mistakes'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((m) => CorrectionMistake(
                step: m['step'] as String? ?? '',
                issue: m['issue'] as String? ?? '',
                type: m['type'] as String? ?? 'reasoning',
              ))
          .where((m) => m.issue.isNotEmpty)
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
    );
  }

  final CorrectionScore score;
  final String whatWasRight;
  final String whatWasWrong;
  final String correctSolution;
  final String encouragement;

  /// clear | partly_readable | unreadable (photos).
  final String readability;
  final List<String> imageIssues;
  final bool retakePhoto;

  /// What the AI read from the student's work.
  final String transcription;

  /// official | alternative_valid | invalid | unclear
  final String method;
  final bool? reasoningCorrect;
  final bool? calculationCorrect;
  final bool? finalAnswerCorrect;
  final List<String> correctSteps;
  final List<CorrectionMistake> mistakes;
  final double confidence;

  bool get undetermined => score == CorrectionScore.undetermined;
}
