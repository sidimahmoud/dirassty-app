import 'package:flutter/foundation.dart';

import 'diagram_spec.dart';

/// A multiple-choice (QCM) exercise. Ported from `ExerciseBody` in
/// packages/shared/src/types — the body of a `content` row where
/// `type = 'exercise'`.
@immutable
class ExerciseBody {
  const ExerciseBody({
    required this.question,
    required this.choices,
    required this.correct,
    required this.explanation,
    required this.hint,
    required this.concept,
    this.diagram,
  });

  /// Tolerant of admin-written rows: the web's manual form omits empty
  /// optional fields (explanation / hint / concept) and can store blank
  /// choice slots — blanks are dropped and [correct] remapped onto the
  /// remaining choices. Throws only if the question or choices are
  /// unusable (the repository then skips just that row).
  factory ExerciseBody.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['choices'] as List<dynamic>? ?? const [];
    final int rawCorrect = (json['correct'] as num?)?.toInt() ?? 0;
    final List<String> choices = [];
    int correct = 0;
    for (int i = 0; i < raw.length; i++) {
      final String c = (raw[i]?.toString() ?? '').trim();
      if (c.isEmpty) continue;
      if (i == rawCorrect) correct = choices.length;
      choices.add(c);
    }
    final String question = (json['question'] as String? ?? '').trim();
    if (question.isEmpty || choices.length < 2) {
      throw const FormatException('QCM without a question or 2 choices');
    }
    return ExerciseBody(
      question: question,
      choices: choices,
      correct: correct,
      explanation: json['explanation'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      concept: json['concept'] as String? ?? '',
      diagram: DiagramSpec.tryParse(json['diagram'] as Map<String, dynamic>?),
    );
  }

  final String question;

  /// 2–4 non-empty choices (AI rows always have 4).
  final List<String> choices;

  /// Index (0–3) of the correct choice.
  final int correct;
  final String explanation;
  final String hint;
  final String concept;

  /// Only present when the question genuinely needs a visual — see
  /// [DiagramSpec]'s doc comment.
  final DiagramSpec? diagram;
}
