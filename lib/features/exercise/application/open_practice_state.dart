import '../../../core/models/open_exercise_body.dart';
import '../../../core/models/open_exercise_correction.dart';

enum OpenPracticePhase { answering, hint, correcting, corrected, generating }

sealed class OpenPracticeState {
  const OpenPracticeState();
}

final class OppLoading extends OpenPracticeState {
  const OppLoading();
}

/// No `open_exercise` content rows exist for this lesson yet.
final class OppEmpty extends OpenPracticeState {
  const OppEmpty();
}

final class OppError extends OpenPracticeState {
  const OppError(this.message);
  final String message;
}

/// One active open exercise, at any point in the
/// answering → hint → correcting → corrected (→ generating a follow-up)
/// cycle. `exerciseIndex` tracks position in the pre-made pool for
/// "next exercise" navigation — a generated (similar) exercise keeps the
/// same index (it's a follow-up to that slot, not a new pool entry).
final class OppActive extends OpenPracticeState {
  const OppActive({
    required this.poolSize,
    required this.exerciseIndex,
    required this.grade,
    required this.lang,
    required this.activeId,
    required this.activeBody,
    required this.attempt,
    required this.phase,
    this.generatedToken,
    this.draftAnswer = '',
    this.submittedAnswer = '',
    this.correction,
    this.apiError,
  });

  final int poolSize;
  final int exerciseIndex;
  final int grade;
  final String lang;
  final String activeId;
  final OpenExerciseBody activeBody;

  /// Set for an AI follow-up exercise (not saved, so no content id): the
  /// encrypted token that identifies it to the server.
  final String? generatedToken;

  /// How the AI routes identify this exercise — never by its solution.
  Map<String, String> get exerciseRef => generatedToken != null
      ? {'generated_token': generatedToken!}
      : {'content_id': activeId};
  final int attempt;
  final OpenPracticePhase phase;
  final String draftAnswer;
  final String submittedAnswer;
  final OpenExerciseCorrection? correction;
  final String? apiError;

  bool get hasNextPremade => exerciseIndex < poolSize - 1;

  OppActive copyWith({
    String? activeId,
    OpenExerciseBody? activeBody,
    int? exerciseIndex,
    int? attempt,
    OpenPracticePhase? phase,
    String? draftAnswer,
    String? submittedAnswer,
    OpenExerciseCorrection? correction,
    bool clearCorrection = false,
    String? apiError,
    bool clearApiError = false,
  }) {
    return OppActive(
      poolSize: poolSize,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      grade: grade,
      lang: lang,
      activeId: activeId ?? this.activeId,
      activeBody: activeBody ?? this.activeBody,
      generatedToken: generatedToken,
      attempt: attempt ?? this.attempt,
      phase: phase ?? this.phase,
      draftAnswer: draftAnswer ?? this.draftAnswer,
      submittedAnswer: submittedAnswer ?? this.submittedAnswer,
      correction: clearCorrection ? null : (correction ?? this.correction),
      apiError: clearApiError ? null : (apiError ?? this.apiError),
    );
  }
}
