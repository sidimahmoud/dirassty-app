import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/gamification/gamification.dart';
import '../../../core/models/content.dart';
import '../../../core/models/progress.dart';
import '../../courses/application/courses_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import 'exercise_providers.dart';
import 'qcm_session_state.dart';

/// Drives one fixed 5-question QCM session for a lesson. Ported from the
/// handler sequence in
/// apps/web/app/(student)/exercise/[id]/page.tsx:
/// - mastery is written per answered question (never per-hint or per-skip)
/// - XP is accumulated locally during the session and written ONCE, at
///   the end, alongside a streak update and a perfect-session bonus check
/// - there is no mid-session adaptive difficulty — the question set is
///   fixed at load time
final class QcmSessionController extends StateNotifier<QcmSessionState> {
  QcmSessionController(this._ref, this._lessonId) : super(const QcmLoading()) {
    _load();
  }

  final Ref _ref;
  final String _lessonId;
  DateTime _sessionStartedAt = DateTime.now();

  Future<void> _load() async {
    _sessionStartedAt = DateTime.now();
    state = const QcmLoading();
    try {
      final List<ExerciseContent> exercises = await _ref
          .read(exerciseRepositoryProvider)
          .getSessionExercises(_lessonId);
      if (exercises.isEmpty) {
        state = const QcmEmpty();
        return;
      }
      state = QcmExercising(
        exercises: exercises,
        currentIndex: 0,
        answers: const [],
        sessionXp: 0,
      );
    } catch (e) {
      state = QcmError(e.toString());
    }
  }

  Future<void> selectChoice(int index) async {
    final QcmSessionState snapshot = state;
    if (snapshot is! QcmExercising || snapshot.answered) return;

    final ExerciseContent exercise = snapshot.current;
    final bool correct = index == exercise.body.correct;
    final QcmAnswerRecord record = QcmAnswerRecord(
      exercise: exercise,
      chosen: index,
      correct: correct,
    );
    final int xpDelta = correct ? xpForCorrectAnswer(exercise.difficulty) : 0;

    // Lock the choice and reveal feedback immediately — same as the web
    // app disabling further taps and showing the result as soon as
    // `answered` flips, before the mastery write resolves. `selectedChoice`
    // and `answers` must land in this SAME state update: `answered` is
    // derived from `selectedChoice` alone, so flipping it without also
    // appending `record` here left a window (worst on the very first
    // question, where `answers` was still empty) where the UI read
    // `state.answered == true` but `state.answers.last` had nothing to
    // return yet.
    state = snapshot.copyWith(
      selectedChoice: index,
      answers: [...snapshot.answers, record],
      sessionXp: snapshot.sessionXp + xpDelta,
    );

    final studentId = (await _ref.read(currentStudentProvider.future)).id;
    await _ref.read(progressRepositoryProvider).updateMastery(
          studentId: studentId,
          lessonId: _lessonId,
          concept: exercise.body.concept,
          correct: correct,
        );
  }

  void toggleHint() {
    final QcmSessionState snapshot = state;
    if (snapshot is! QcmExercising) return;
    state = snapshot.copyWith(hintRevealed: !snapshot.hintRevealed);
  }

  /// Advances to the next question, or — on the last question — finishes
  /// the session: writes the session's total XP in one call, updates the
  /// streak, and re-reads lesson mastery for the results banner.
  Future<void> next() async {
    final QcmSessionState snapshot = state;
    if (snapshot is! QcmExercising) return;

    if (!snapshot.isLast) {
      state = QcmExercising(
        exercises: snapshot.exercises,
        currentIndex: snapshot.currentIndex + 1,
        answers: snapshot.answers,
        sessionXp: snapshot.sessionXp,
      );
      return;
    }

    final student = await _ref.read(currentStudentProvider.future);
    final studentId = student.id;
    final int oldStreak = student.streak;
    final progressRepo = _ref.read(progressRepositoryProvider);

    final int totalXp = calculateSessionXp(
      snapshot.answers
          .map(
            (a) => SessionAnswer(
              correct: a.correct,
              difficulty: a.exercise.difficulty,
            ),
          )
          .toList(),
    );

    await progressRepo.addXp(
      studentId: studentId,
      points: totalXp,
      source: XpSource.exercise,
      metadata: {'lesson_id': _lessonId},
    );
    final int newStreak = await progressRepo.updateStreak(studentId);
    await progressRepo.logStudySession(
      studentId: studentId,
      startedAt: _sessionStartedAt,
    );

    final List<Progress> progressRows = await progressRepo.getProgress(
      studentId,
      _lessonId,
    );
    final double lessonMastery = progressRows.isEmpty
        ? 0
        : progressRows.map((p) => p.mastery).reduce((a, b) => a + b) /
            progressRows.length;

    // The writes above (mastery/XP/streak) just changed the exact data
    // every stats screen reads — but none of those are subscriptions,
    // they're one-shot fetches cached by Riverpod, so nothing re-fetches
    // on its own. Without this, the home header's streak/XP, the weekly
    // stats grid, and every subject/lesson mastery indicator keep
    // showing whatever they first loaded, no matter how many sessions
    // get completed afterward.
    _ref.invalidate(currentStudentProvider);
    _ref.invalidate(studentStatsProvider);
    _ref.invalidate(subjectMasteryProvider);
    _ref.invalidate(subjectsWithMasteryProvider);
    _ref.invalidate(subjectsWithMasteryForStudentProvider);
    _ref.invalidate(lessonMasteryMapProvider);

    state = QcmComplete(
      answers: snapshot.answers,
      totalXp: totalXp,
      lessonMastery: lessonMastery,
      passed: lessonMastery >= 0.85,
      newStreak: newStreak,
      streakIncreased: newStreak > oldStreak,
      duration: DateTime.now().difference(_sessionStartedAt),
    );
  }

  /// Starts a brand-new session with a fresh random 5-question draw — no
  /// server-side attempt-count cap, matching the web app's "Recommencer".
  void retry() => _load();
}

final qcmSessionControllerProvider =
    StateNotifierProvider.family<QcmSessionController, QcmSessionState, String>(
  (ref, lessonId) => QcmSessionController(ref, lessonId),
);
