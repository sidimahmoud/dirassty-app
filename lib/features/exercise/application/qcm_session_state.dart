import '../../../core/models/content.dart';

sealed class QcmSessionState {
  const QcmSessionState();
}

final class QcmLoading extends QcmSessionState {
  const QcmLoading();
}

/// No verified exercises exist for this lesson at any difficulty yet.
final class QcmEmpty extends QcmSessionState {
  const QcmEmpty();
}

final class QcmError extends QcmSessionState {
  const QcmError(this.message);
  final String message;
}

class QcmAnswerRecord {
  const QcmAnswerRecord({
    required this.exercise,
    required this.chosen,
    required this.correct,
  });

  final ExerciseContent exercise;
  final int chosen;
  final bool correct;
}

final class QcmExercising extends QcmSessionState {
  const QcmExercising({
    required this.exercises,
    required this.currentIndex,
    required this.answers,
    required this.sessionXp,
    this.selectedChoice,
    this.hintRevealed = false,
  });

  final List<ExerciseContent> exercises;
  final int currentIndex;
  final List<QcmAnswerRecord> answers;
  final int sessionXp;
  final int? selectedChoice;
  final bool hintRevealed;

  ExerciseContent get current => exercises[currentIndex];
  bool get answered => selectedChoice != null;
  bool get isLast => currentIndex == exercises.length - 1;

  QcmExercising copyWith({
    List<QcmAnswerRecord>? answers,
    int? sessionXp,
    int? selectedChoice,
    bool? hintRevealed,
  }) {
    return QcmExercising(
      exercises: exercises,
      currentIndex: currentIndex,
      answers: answers ?? this.answers,
      sessionXp: sessionXp ?? this.sessionXp,
      selectedChoice: selectedChoice ?? this.selectedChoice,
      hintRevealed: hintRevealed ?? this.hintRevealed,
    );
  }
}

/// `passed` is purely informational copy (mirrors the web app) — nothing
/// blocks navigating to any lesson/exercise regardless of this value.
/// [streakIncreased] is false on a student's second+ finished session of
/// the same day (see ProgressRepository.updateStreak — it's a no-op past
/// the first call today), so the celebration only ever shows once per day.
final class QcmComplete extends QcmSessionState {
  const QcmComplete({
    required this.answers,
    required this.totalXp,
    required this.lessonMastery,
    required this.passed,
    required this.newStreak,
    required this.streakIncreased,
    this.duration = Duration.zero,
  });

  final List<QcmAnswerRecord> answers;
  final int totalXp;
  final double lessonMastery;
  final bool passed;
  final int newStreak;
  final bool streakIncreased;

  /// Time from the session's first question to finishing it.
  final Duration duration;

  int get correctCount => answers.where((a) => a.correct).length;
  int get total => answers.length;
}
