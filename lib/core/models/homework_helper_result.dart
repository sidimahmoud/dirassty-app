import 'package:flutter/foundation.dart';

import 'diagram_spec.dart';

/// Ported from `HomeworkHelperResult` in packages/shared/src/types —
/// result of the standalone AI homework helper. The model decides [kind]
/// itself from the photo; only the fields for that kind are populated.
/// Ephemeral: never persisted anywhere, including on this client.
@immutable
class HomeworkHelperResult {
  const HomeworkHelperResult({
    required this.kind,
    required this.detectedSubject,
    required this.detectedTopic,
    this.problemStatement,
    this.steps,
    this.fullSolution,
    this.figure,
    this.finalAnswer,
    this.keyConcepts,
    this.explanation,
    this.readable = true,
    this.imageIssues = const [],
  });

  factory HomeworkHelperResult.fromJson(Map<String, dynamic> json) {
    return HomeworkHelperResult(
      kind: json['kind'] as String? ?? 'explain',
      detectedSubject: json['detected_subject'] as String? ?? '',
      detectedTopic: json['detected_topic'] as String? ?? '',
      problemStatement: json['problem_statement'] as String?,
      steps: (json['steps'] as List<dynamic>?)?.cast<String>(),
      fullSolution: json['full_solution'] as String?,
      figure: DiagramSpec.tryParse(json['figure'] as Map<String, dynamic>?),
      finalAnswer: json['final_answer'] as String?,
      keyConcepts: (json['key_concepts'] as List<dynamic>?)?.cast<String>(),
      explanation: json['explanation'] as String?,
      readable: json['readable'] as bool? ?? true,
      imageIssues:
          (json['image_issues'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// 'solve' | 'explain'.
  final String kind;
  final String detectedSubject;
  final String detectedTopic;

  // 'solve'
  final String? problemStatement;
  final List<String>? steps;

  /// Complete written model answer (every sub-question, all calculations)
  /// — what "show the answer" reveals. Null from older API responses.
  final String? fullSolution;

  /// Geometry / coordinate-plane figure drawn to scale (DiagramView);
  /// null when the exercise has no figure.
  final DiagramSpec? figure;
  final String? finalAnswer;

  // 'explain'
  final List<String>? keyConcepts;
  final String? explanation;

  /// false when the AI couldn't read the photo reliably — the screen asks
  /// for a retake instead of showing a guessed answer.
  final bool readable;

  /// e.g. "blurry", "dark", "rotated", "cropped", "illegible".
  final List<String> imageIssues;

  bool get isSolve => kind == 'solve';
}
