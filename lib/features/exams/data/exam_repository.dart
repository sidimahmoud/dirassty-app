import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/exam.dart';

/// The only place in the app that reads/writes `exams`/`exam_questions`.
/// Generation, the weekly reveal, and the missed-sweep all happen
/// server-side (see supabase/functions/generate-weekly-exams) — this
/// repository only ever reads what already exists and records a
/// student's answers/completion for one exam.
class ExamRepository {
  ExamRepository(this._client);

  final SupabaseClient _client;

  static const String _examSelect = '*, subject:subject_id(key, label, icon)';

  /// Every exam this student has ever had, newest week first — the
  /// student's own "Examens" list mixes this week's with recent history;
  /// the parent's historique view uses the exact same rows read-only.
  Future<List<Exam>> getExamsForStudent(String studentId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('exams')
        .select(_examSelect)
        .eq('student_id', studentId)
        .order('week_start', ascending: false);
    return rows.map(Exam.fromJson).toList();
  }

  Future<ExamDetail> getExamDetail(String examId) async {
    final Map<String, dynamic> examRow = await _client
        .from('exams')
        .select(_examSelect)
        .eq('id', examId)
        .single();
    final List<Map<String, dynamic>> questionRows = await _client
        .from('exam_questions')
        .select(
          '*, content:content_id(body, difficulty), lesson:lesson_id(title)',
        )
        .eq('exam_id', examId)
        .order('order_index');
    return ExamDetail(
      exam: Exam.fromJson(examRow),
      questions: questionRows.map(ExamQuestion.fromJson).toList(),
    );
  }

  /// First tap into the taking flow — a no-op if already started (no
  /// column to guard on client-side, but calling this more than once is
  /// harmless, it just re-stamps the same intent).
  Future<void> markStarted(String examId) async {
    await _client.from('exams').update(
      {'started_at': DateTime.now().toIso8601String()},
    ).eq('id', examId);
  }

  Future<void> answerQuestion({
    required String questionId,
    required int selectedChoice,
    required bool isCorrect,
  }) async {
    await _client.from('exam_questions').update({
      'selected_choice': selectedChoice,
      'is_correct': isCorrect,
      'answered_at': DateTime.now().toIso8601String(),
    }).eq('id', questionId);
  }

  /// Only stamps the exam row itself (status/score/xp_awarded) — the
  /// actual XP ledger write (xp_events + students.xp_total/level) goes
  /// through ProgressRepository.addXp, same as every other XP-earning
  /// action in the app (see ExamSessionController.next()).
  Future<void> completeExam({
    required String examId,
    required int correctCount,
    required int xpAwarded,
  }) async {
    await _client.from('exams').update({
      'status': 'completed',
      'correct_count': correctCount,
      'xp_awarded': xpAwarded,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', examId);
  }
}
