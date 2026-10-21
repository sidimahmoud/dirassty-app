import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/gamification/gamification.dart';
import '../../../core/models/exam.dart';
import '../../auth/application/auth_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import '../data/exam_repository.dart';
import 'exam_session_state.dart';

final Provider<ExamRepository> examRepositoryProvider = Provider(
  (ref) => ExamRepository(ref.watch(supabaseClientProvider)),
);

/// Every exam a given student has ever had, newest week first — used
/// both by that student's own "Examens" list and, unmodified, by the
/// parent's read-only historique for that child (see
/// ChildExamHistoryScreen). Keyed by student id rather than "the current
/// student" so both callers can share one provider.
final examsByStudentProvider = FutureProvider.family<List<Exam>, String>((
  ref,
  studentId,
) {
  return ref.watch(examRepositoryProvider).getExamsForStudent(studentId);
});

/// Drives one exam-taking session: loads the exam's frozen question
/// snapshot, records each answer as it's chosen (same "write immediately,
/// don't wait for session end" approach as QcmSessionController), and on
/// the last question awards XP/streak exactly the way a QCM session does
/// (per-correct-answer reward plus a flat completion bonus — see
/// XpRewards.examCompletionBonus) before marking the exam completed.
final class ExamSessionController extends StateNotifier<ExamSessionState> {
  ExamSessionController(this._ref, this._examId)
      : super(const ExamSessionLoading()) {
    _load();
  }

  final Ref _ref;
  final String _examId;
  DateTime _startedAt = DateTime.now();

  Future<void> _load() async {
    _startedAt = DateTime.now();
    state = const ExamSessionLoading();
    try {
      final ExamRepository repo = _ref.read(examRepositoryProvider);
      final ExamDetail detail = await repo.getExamDetail(_examId);
      if (detail.exam.status != ExamStatus.completed) {
        // Fire-and-forget: `started_at` is informational only, nothing
        // downstream waits on it, so it shouldn't hold up rendering.
        unawaited(repo.markStarted(_examId));
      }
      if (detail.exam.status == ExamStatus.completed) {
        // Re-opening a past exam — show the XP it actually earned (now
        // persisted on the row), but no streak celebration: that's a
        // one-time thing tied to the moment it was first finished.
        state = ExamSessionComplete(
          exam: detail.exam,
          questions: detail.questions,
          totalXp: detail.exam.xpAwarded ?? 0,
        );
        return;
      }
      state = ExamSessionActive(
        exam: detail.exam,
        questions: detail.questions,
        // Resume on the first question not answered yet.
        currentIndex: detail.questions
            .indexWhere((q) => !q.answered)
            .clamp(0, detail.questions.length - 1),
        startedAt: _startedAt,
      );
    } catch (e) {
      state = ExamSessionError(e.toString());
    }
  }

  /// Picks (or changes) the current question's answer — shown at once,
  /// saved to the server in the background. No feedback during the exam.
  Future<void> selectChoice(int index) async {
    final ExamSessionState snapshot = state;
    if (snapshot is! ExamSessionActive || snapshot.finishing) return;

    final int at = snapshot.currentIndex;
    final ExamQuestion question = snapshot.current;
    final bool correct = index == question.body.correct;
    final List<ExamQuestion> updated = [...snapshot.questions];
    updated[at] = ExamQuestion(
      id: question.id,
      lessonId: question.lessonId,
      lessonTitle: question.lessonTitle,
      orderIndex: question.orderIndex,
      difficulty: question.difficulty,
      body: question.body,
      selectedChoice: index,
      isCorrect: correct,
    );
    state = snapshot.copyWith(questions: updated);
    await _ref.read(examRepositoryProvider).answerQuestion(
          questionId: question.id,
          selectedChoice: index,
          isCorrect: correct,
        );
  }

  void goTo(int index) {
    final ExamSessionState snapshot = state;
    if (snapshot is! ExamSessionActive) return;
    if (index < 0 || index >= snapshot.questions.length) return;
    state = snapshot.copyWith(currentIndex: index);
  }

  void previous() {
    final ExamSessionState s = state;
    if (s is ExamSessionActive) goTo(s.currentIndex - 1);
  }

  void next() {
    final ExamSessionState s = state;
    if (s is ExamSessionActive) goTo(s.currentIndex + 1);
  }

  /// Submits the exam — from "Terminer l'examen", or automatically when a
  /// timed exam runs out. Unanswered questions count as wrong.
  Future<void> finish() async {
    final ExamSessionState snapshot = state;
    if (snapshot is! ExamSessionActive || snapshot.finishing) return;
    state = snapshot.copyWith(finishing: true);
    try {
      final int correctCount =
          snapshot.questions.where((q) => q.isCorrect == true).length;
      final int totalXp = snapshot.questions
              .where((q) => q.isCorrect == true)
              .fold(0, (sum, q) => sum + xpForCorrectAnswer(q.difficulty)) +
          XpRewards.examCompletionBonus;

      final progressRepo = _ref.read(progressRepositoryProvider);
      final String studentId = snapshot.exam.studentId;
      // Read before updateStreak mutates it, so streakIncreased below is
      // meaningful — mirrors QcmSessionController.next().
      final int oldStreak =
          (await _ref.read(currentStudentProvider.future)).streak;

      await _ref.read(examRepositoryProvider).completeExam(
            examId: _examId,
            correctCount: correctCount,
            xpAwarded: totalXp,
          );
      await progressRepo.addXp(
        studentId: studentId,
        points: totalXp,
        source: XpSource.exam,
        metadata: {'exam_id': _examId, 'subject_id': snapshot.exam.subject.key},
      );
      final int newStreak = await progressRepo.updateStreak(studentId);
      unawaited(
        progressRepo.logStudySession(
          studentId: studentId,
          startedAt: _startedAt,
        ),
      );

      _ref.invalidate(examsByStudentProvider(studentId));
      _ref.invalidate(currentStudentProvider);
      state = ExamSessionComplete(
        exam: snapshot.exam,
        questions: snapshot.questions,
        totalXp: totalXp,
        newStreak: newStreak,
        streakIncreased: newStreak > oldStreak,
        duration: DateTime.now().difference(snapshot.startedAt),
      );
    } catch (_) {
      // Let the student retry the submit instead of staying stuck.
      final ExamSessionState current = state;
      if (current is ExamSessionActive) {
        state = current.copyWith(finishing: false);
      }
      rethrow;
    }
  }
}

final examSessionControllerProvider = StateNotifierProvider.family<
    ExamSessionController, ExamSessionState, String>(
  (ref, examId) => ExamSessionController(ref, examId),
);
