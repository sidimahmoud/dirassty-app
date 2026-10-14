import 'package:flutter/foundation.dart';

import '../i18n/app_lang.dart';
import 'diagram_spec.dart';

/// One worked example: a concrete scenario, short step-by-step reasoning,
/// and result. Several of these — not a paragraph — are how a concept is
/// taught. Ported from `WorkedExample` in packages/shared/src/types.
@immutable
class WorkedExample {
  const WorkedExample({
    required this.scenario,
    required this.steps,
    required this.result,
    this.diagram,
  });

  factory WorkedExample.fromJson(Map<String, dynamic> json) {
    return WorkedExample(
      scenario: json['scenario'] as String,
      steps: (json['steps'] as List<dynamic>).cast<String>(),
      result: json['result'] as String,
      diagram: DiagramSpec.tryParse(json['diagram'] as Map<String, dynamic>?),
    );
  }

  final String scenario;
  final List<String> steps;
  final String result;

  /// Only present when this example genuinely needs a visual — see
  /// [DiagramSpec]'s doc comment.
  final DiagramSpec? diagram;
}

/// A comprehension-gate question shown after a concept's examples. Ported
/// from `ConceptCheck` in packages/shared/src/types.
@immutable
class ConceptCheck {
  const ConceptCheck({
    required this.question,
    required this.choices,
    required this.correct,
    required this.explanation,
  });

  factory ConceptCheck.fromJson(Map<String, dynamic> json) {
    return ConceptCheck(
      question: json['question'] as String,
      choices: (json['choices'] as List<dynamic>).cast<String>(),
      correct: json['correct'] as int,
      explanation: json['explanation'] as String,
    );
  }

  final String question;
  final List<String> choices;
  final int correct;
  final String explanation;
}

/// One taught concept: a short core idea, worked examples, and a
/// comprehension check that gates moving to the next concept. Ported from
/// `ConceptSection` in packages/shared/src/types. Older generated content
/// used a prose `explanation`/`realLifeExample` pair instead of
/// `coreIdea`/`examples` — both are rendered where present (see
/// ConceptStepView).
@immutable
class ConceptSection {
  const ConceptSection({
    required this.title,
    required this.check,
    this.coreIdea,
    this.examples = const [],
    this.explanation,
    this.realLifeExample,
  });

  factory ConceptSection.fromJson(Map<String, dynamic> json) {
    return ConceptSection(
      title: json['title'] as String,
      check: ConceptCheck.fromJson(json['check'] as Map<String, dynamic>),
      coreIdea: json['core_idea'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => WorkedExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      explanation: json['explanation'] as String?,
      realLifeExample: json['real_life_example'] as String?,
    );
  }

  final String title;
  final ConceptCheck check;
  final String? coreIdea;
  final List<WorkedExample> examples;
  final String? explanation;
  final String? realLifeExample;

  bool get hasExamples => examples.isNotEmpty;
}

/// Ported from `ExplanationBody` in packages/shared/src/types — the body
/// of a `content` row where `type = 'explanation'`. `sections` is the
/// current generation format; `text`/`workedExample` is the legacy flat
/// format some older content still uses (see LessonViewerScreen for how
/// both are rendered).
@immutable
class ExplanationBody {
  const ExplanationBody({
    required this.lang,
    required this.keyConcepts,
    this.sections = const [],
    this.text,
    this.workedExample,
  });

  factory ExplanationBody.fromJson(Map<String, dynamic> json) {
    return ExplanationBody(
      lang: AppLang.fromDb(json['lang'] as String),
      keyConcepts: (json['key_concepts'] as List<dynamic>).cast<String>(),
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => ConceptSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      text: json['text'] as String?,
      workedExample: json['worked_example'] as String?,
    );
  }

  final AppLang lang;
  final List<String> keyConcepts;
  final List<ConceptSection> sections;
  final String? text;
  final String? workedExample;

  bool get hasStructuredSections => sections.isNotEmpty;
}
