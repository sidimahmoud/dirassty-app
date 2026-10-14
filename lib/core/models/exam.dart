import 'package:flutter/foundation.dart';

import 'difficulty.dart';
import 'exercise_body.dart';

/// A weekly per-subject review exam's lifecycle — see
/// supabase/migrations/032_weekly_exams.sql and the generate-weekly-exams
/// Edge Function for how a row moves through these. 'missed' is
/// terminal and non-recoverable by design (see that migration's
/// comment) — it's what lets a parent see which weeks were skipped.
enum ExamStatus {
  /// Generated, but its `available_from` hasn't arrived yet — never
  /// shown to the student, only used internally by the reveal sweep.
  scheduled,
  available,
  completed,
  missed;

  static ExamStatus fromDb(String value) => switch (value) {
        'scheduled' => ExamStatus.scheduled,
        'available' => ExamStatus.available,
        'completed' => ExamStatus.completed,
        'missed' => ExamStatus.missed,
        _ => ExamStatus.scheduled,
      };
}

/// A `subjects` row's display fields, as nested into an exam query —
/// deliberately not the full [Subject] model (no mastery/grade context
/// makes sense on an exam card).
@immutable
class ExamSubject {
  const ExamSubject(
      {required this.key, required this.label, required this.icon});

  factory ExamSubject.fromJson(Map<String, dynamic> json) {
    return ExamSubject(
      key: json['key'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
    );
  }

  final String key;
  final String label;
  final String icon;
}

/// One `exams` row — a single subject's review exam for one calendar
/// week. Ordered/filtered client-side by [weekStart]/[status], never
/// re-derived: the server (generate-weekly-exams) owns every status
/// transition.
@immutable
class Exam {
  const Exam({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.weekStart,
    required this.availableFrom,
    required this.dueAt,
    required this.status,
    required this.totalQuestions,
    required this.correctCount,
    required this.xpAwarded,
    required this.completedAt,
    this.durationMinutes,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      subject: ExamSubject.fromJson(json['subject'] as Map<String, dynamic>),
      weekStart: DateTime.parse(json['week_start'] as String),
      availableFrom: DateTime.parse(json['available_from'] as String),
      dueAt: DateTime.parse(json['due_at'] as String),
      status: ExamStatus.fromDb(json['status'] as String),
      totalQuestions: json['total_questions'] as int,
      correctCount: json['correct_count'] as int?,
      xpAwarded: json['xp_awarded'] as int?,
      durationMinutes: json['duration_minutes'] as int?,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );
  }

  final String id;
  final String studentId;
  final ExamSubject subject;
  final DateTime weekStart;
  final DateTime availableFrom;
  final DateTime dueAt;
  final ExamStatus status;
  final int totalQuestions;
  final int? correctCount;
  final int? xpAwarded;
  final DateTime? completedAt;

  /// Time limit, when the exam has one. TODO(api): not stored yet — until
  /// it is, sessions show elapsed time instead of a countdown.
  final int? durationMinutes;

  double? get scoreRatio => correctCount == null || totalQuestions == 0
      ? null
      : correctCount! / totalQuestions;
}

/// One `exam_questions` row joined with its frozen `content` snapshot and
/// the lesson it came from — a completed one already carries the
/// student's answer, an unanswered one doesn't.
@immutable
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.orderIndex,
    required this.difficulty,
    required this.body,
    required this.selectedChoice,
    required this.isCorrect,
  });

  /// Prefers the question snapshot stored on the exam itself (047 —
  /// always present for new exams, and the only source for AI-written
  /// questions, which have no practice exercise or lesson behind them);
  /// falls back to the linked exercise for older exams.
  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? content =
        json['content'] as Map<String, dynamic>?;
    final Map<String, dynamic>? lesson =
        json['lesson'] as Map<String, dynamic>?;
    final Map<String, dynamic> body = (json['body'] as Map<String, dynamic>?) ??
        (content?['body'] as Map<String, dynamic>? ?? const {});
    return ExamQuestion(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      lessonTitle: lesson?['title'] as String? ?? '',
      orderIndex: json['order_index'] as int,
      difficulty:
          Difficulty.fromDb(content?['difficulty'] as String? ?? 'medium'),
      body: ExerciseBody.fromJson(body),
      selectedChoice: json['selected_choice'] as int?,
      isCorrect: json['is_correct'] as bool?,
    );
  }

  final String id;
  final String lessonId;
  final String lessonTitle;
  final int orderIndex;
  final Difficulty difficulty;
  final ExerciseBody body;
  final int? selectedChoice;
  final bool? isCorrect;

  bool get answered => selectedChoice != null;
}

@immutable
class ExamDetail {
  const ExamDetail({required this.exam, required this.questions});

  final Exam exam;
  final List<ExamQuestion> questions;
}
