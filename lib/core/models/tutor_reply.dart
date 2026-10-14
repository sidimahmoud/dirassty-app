import 'package:flutter/foundation.dart';

/// One tutor message — `TutorReply` in packages/shared/src/lib/tutor.ts,
/// returned by `POST /api/tutor`.
@immutable
class TutorReply {
  const TutorReply({
    required this.kind,
    required this.reply,
    this.stepStatus,
    this.steps = const [],
    this.formulas = const [],
    this.finalAnswer = '',
    this.suggestions = const [],
    this.budgetLeftPct,
  });

  factory TutorReply.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? usage =
        json['ai_usage'] as Map<String, dynamic>?;
    return TutorReply(
      kind: json['kind'] as String? ?? 'explanation',
      reply: json['reply'] as String? ?? '',
      stepStatus: json['step_status'] as String?,
      steps: ((json['steps'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((s) => (
                work: s['work'] as String? ?? '',
                why: s['why'] as String? ?? ''
              ))
          .where((s) => s.work.isNotEmpty)
          .toList(),
      formulas:
          (json['formulas'] as List<dynamic>?)?.cast<String>() ?? const [],
      finalAnswer: json['final_answer'] as String? ?? '',
      suggestions:
          (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? const [],
      budgetLeftPct: (usage?['pct_left'] as num?)?.toInt(),
    );
  }

  /// hint | question | feedback | explanation | solution
  final String kind;
  final String reply;

  /// For "check my step": correct | partially_correct | incorrect.
  final String? stepStatus;

  /// Full-solution steps (only for the "solution" action).
  final List<({String work, String why})> steps;
  final List<String> formulas;
  final String finalAnswer;
  final List<String> suggestions;

  /// Share of today's AI help left, 0-100 (server-computed), when known.
  final int? budgetLeftPct;

  bool get isHint => kind == 'hint';
}

/// A turn of the tutor conversation, as sent back to `/api/tutor`
/// (the server trims and caps it — LIMITS in tutor.ts).
@immutable
class TutorTurn {
  const TutorTurn(
      {required this.fromStudent, required this.text, this.isHint = false});

  final bool fromStudent;
  final String text;
  final bool isHint;

  Map<String, dynamic> toJson() => {
        'role': fromStudent ? 'student' : 'tutor',
        'text': text,
        if (isHint) 'kind': 'hint',
      };
}
