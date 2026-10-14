import '../../../core/models/exam.dart';

sealed class ExamSessionState {
  const ExamSessionState();
}

final class ExamSessionLoading extends ExamSessionState {
  const ExamSessionLoading();
}

final class ExamSessionError extends ExamSessionState {
  const ExamSessionError(this.message);
  final String message;
}

/// A running exam. Questions can be visited in any order and answers
/// changed until [ExamSessionController.finish]; each answer is kept on
/// its own [ExamQuestion] (and saved to the server as it's picked).
final class ExamSessionActive extends ExamSessionState {
  const ExamSessionActive({
    required this.exam,
    required this.questions,
    required this.currentIndex,
    required this.startedAt,
    this.finishing = false,
  });

  final Exam exam;
  final List<ExamQuestion> questions;
  final int currentIndex;
  final DateTime startedAt;

  /// True while the finish write is in flight.
  final bool finishing;

  ExamQuestion get current => questions[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == questions.length - 1;
  int get answeredCount => questions.where((q) => q.answered).length;

  ExamSessionActive copyWith({
    List<ExamQuestion>? questions,
    int? currentIndex,
    bool? finishing,
  }) {
    return ExamSessionActive(
      exam: exam,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: startedAt,
      finishing: finishing ?? this.finishing,
    );
  }
}

final class ExamSessionComplete extends ExamSessionState {
  const ExamSessionComplete({
    required this.exam,
    required this.questions,
    this.totalXp = 0,
    this.newStreak,
    this.streakIncreased = false,
    this.duration,
  });

  final Exam exam;
  final List<ExamQuestion> questions;

  /// The XP this exam earned, whether just now or (re-reading it from
  /// the persisted row) on a past visit — see
  /// ExamSessionController._load/next. Never re-awarded on a revisit.
  final int totalXp;
  final int? newStreak;
  final bool streakIncreased;

  /// Time taken — known only right after finishing, null when re-opening
  /// a past exam.
  final Duration? duration;

  int get correctCount => questions.where((q) => q.isCorrect == true).length;
  int get total => questions.length;
}
