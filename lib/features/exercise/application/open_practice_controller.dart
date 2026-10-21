import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_language_provider.dart';
import '../../../core/models/content.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/open_exercise_body.dart';
import '../../courses/application/courses_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import 'exercise_providers.dart';
import 'open_practice_state.dart';

/// Drives the open-ended (AI-corrected) exercise flow. Ported from
/// apps/web/app/(student)/open-practice/[id]/page.tsx.
///
/// The "submission" the `OpenExerciseBody.hint` doc comment refers to is
/// the *first* of two submit steps: submitting a draft answer reveals the
/// hint (a pure client-side transition, no network call); only the
/// second submit — after reading the hint — triggers the AI correction
/// call. No mastery/XP is written for open exercises anywhere in this
/// flow, matching the web app (those only come from the QCM flow) — the
/// one thing this flow does persist is [_markOpenPracticeViewed], purely
/// so the lesson resume screen can tell "never touched the exercises for
/// this lesson" apart from "did them at least once" (see
/// 039_open_practice_views.sql).
final class OpenPracticeController extends StateNotifier<OpenPracticeState> {
  OpenPracticeController(this._ref, this._lessonId)
      : super(const OppLoading()) {
    _load();
  }

  final Ref _ref;
  final String _lessonId;
  List<OpenExerciseContent> _pool = const [];

  Future<void> _load() async {
    state = const OppLoading();
    try {
      final results = await Future.wait([
        _ref.read(exerciseRepositoryProvider).getOpenExercises(_lessonId),
        _ref.read(lessonByIdProvider(_lessonId).future),
      ]);
      _pool = results[0] as List<OpenExerciseContent>;
      final CurriculumLesson lesson = results[1] as CurriculumLesson;

      if (_pool.isEmpty) {
        state = const OppEmpty();
        return;
      }
      _activate(
        id: _pool[0].id,
        body: _pool[0].body,
        index: 0,
        attempt: 1,
        grade: lesson.grade,
        lang: lesson.subjectLang.dbValue,
      );
    } catch (e) {
      state = OppError(e.toString());
    }
  }

  void _activate({
    required String id,
    required OpenExerciseBody body,
    required int index,
    required int attempt,
    required int grade,
    required String lang,
    String? generatedToken,
  }) {
    state = OppActive(
      poolSize: _pool.length,
      exerciseIndex: index,
      grade: grade,
      lang: lang,
      activeId: id,
      activeBody: body,
      generatedToken: generatedToken,
      attempt: attempt,
      phase: OpenPracticePhase.answering,
    );
  }

  void updateDraft(String value) {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive ||
        snapshot.phase != OpenPracticePhase.answering) {
      return;
    }
    state = snapshot.copyWith(draftAnswer: value);
  }

  /// The first "submission" — a local phase transition to reveal the
  /// hint, not a network call.
  void submitDraft() {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive) return;
    final String trimmed = snapshot.draftAnswer.trim();
    if (trimmed.length < 3) return;
    state = snapshot.copyWith(
      submittedAnswer: trimmed,
      phase: OpenPracticePhase.hint,
    );
  }

  /// "Corriger ma réponse": back to editing the same exercise with the
  /// previous answer pre-filled — from the hint step (change it before
  /// asking for the correction) or after a correction (a new attempt).
  void reviseAnswer() {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive) return;
    if (snapshot.phase != OpenPracticePhase.hint &&
        snapshot.phase != OpenPracticePhase.corrected) {
      return;
    }
    state = snapshot.copyWith(
      phase: OpenPracticePhase.answering,
      draftAnswer: snapshot.submittedAnswer,
      attempt: snapshot.phase == OpenPracticePhase.corrected
          ? snapshot.attempt + 1
          : snapshot.attempt,
      clearCorrection: true,
      clearApiError: true,
    );
  }

  /// The second, final submission — this is what actually calls the AI
  /// grading route. On failure, reverts to the `hint` phase (not back to
  /// `answering`) so the student's answer/hint stay visible and retry is
  /// just re-tapping the same button.
  Future<void> requestCorrection() async {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive) return;
    state = snapshot.copyWith(
      phase: OpenPracticePhase.correcting,
      clearApiError: true,
    );
    try {
      final correction =
          await _ref.read(exerciseRepositoryProvider).correctOpenExercise(
                exerciseRef: snapshot.exerciseRef,
                studentAnswer: snapshot.submittedAnswer,
                lang: _explainLang,
              );
      final OpenPracticeState afterAwait = state;
      if (afterAwait is! OppActive) return;
      state = afterAwait.copyWith(
        phase: OpenPracticePhase.corrected,
        correction: correction,
      );
      _markOpenPracticeViewed();
    } catch (e) {
      final OpenPracticeState afterAwait = state;
      if (afterAwait is! OppActive) return;
      state = afterAwait.copyWith(
        phase: OpenPracticePhase.hint,
        apiError: e.toString(),
      );
    }
  }

  /// Checks a handwritten solution from 1-3 photos (page order) instead of
  /// a typed answer. On failure (incl. the AI budget being used up) the
  /// error is shown and the student stays where they were.
  Future<void> checkPhotos(
    List<({Uint8List bytes, String filename})> photos,
  ) async {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive || photos.isEmpty) return;
    final OpenPracticePhase before = snapshot.phase;
    state = snapshot.copyWith(
      phase: OpenPracticePhase.correcting,
      clearApiError: true,
    );
    try {
      final correction =
          await _ref.read(exerciseRepositoryProvider).checkSolutionPhotos(
                exerciseRef: snapshot.exerciseRef,
                photos: photos,
                lang: _explainLang,
              );
      final OpenPracticeState afterAwait = state;
      if (afterAwait is! OppActive) return;
      state = afterAwait.copyWith(
        phase: OpenPracticePhase.corrected,
        correction: correction,
      );
      if (!correction.undetermined) _markOpenPracticeViewed();
    } catch (e) {
      final OpenPracticeState afterAwait = state;
      if (afterAwait is! OppActive) return;
      state = afterAwait.copyWith(phase: before, apiError: e.toString());
    }
  }

  /// Offered after both a correct AND an incorrect/partial result —
  /// mirrors the web app exactly, which shows this CTA regardless of
  /// score (just under a different label). On failure, stays on
  /// `corrected` with the previous correction still visible.
  Future<void> requestSimilarExercise() async {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive) return;
    state = snapshot.copyWith(
      phase: OpenPracticePhase.generating,
      clearApiError: true,
    );
    try {
      final generated =
          await _ref.read(exerciseRepositoryProvider).generateSimilarExercise(
                exerciseRef: snapshot.exerciseRef,
                lang: snapshot.lang,
              );
      _activate(
        id: 'gen-${DateTime.now().millisecondsSinceEpoch}',
        body: generated.body,
        generatedToken: generated.token,
        index: snapshot.exerciseIndex,
        attempt: snapshot.attempt + 1,
        grade: snapshot.grade,
        lang: snapshot.lang,
      );
    } catch (e) {
      final OpenPracticeState afterAwait = state;
      if (afterAwait is! OppActive) return;
      state = afterAwait.copyWith(
        phase: OpenPracticePhase.corrected,
        apiError: e.toString(),
      );
    }
  }

  /// The AI writes its corrections in the app's language (Arabic UI →
  /// Arabic explanations, even for a subject taught in French); the
  /// exercise itself stays in the subject's language ([OppActive.lang]).
  String get _explainLang => _ref.read(appLanguageProvider).dbValue;

  /// Fire-and-forget, upserts and ignores a repeat — see
  /// [ProgressRepository.markOpenPracticeViewed]. Never awaited: a
  /// failure here must never surface as an error on what is, to the
  /// student, a successful correction.
  void _markOpenPracticeViewed() {
    final String? studentId = _ref.read(currentStudentProvider).valueOrNull?.id;
    if (studentId == null) return;
    _ref
        .read(progressRepositoryProvider)
        .markOpenPracticeViewed(studentId: studentId, lessonId: _lessonId);
  }

  /// Moves to the next pre-made exercise, resetting the attempt counter.
  /// Callers should check `hasNextPremade` first — when there's none
  /// left, the screen navigates back to the lesson instead of calling
  /// this (mirrors the web app's `router.push` fallback).
  void nextPremadeExercise() {
    final OpenPracticeState snapshot = state;
    if (snapshot is! OppActive || !snapshot.hasNextPremade) return;
    final int nextIndex = snapshot.exerciseIndex + 1;
    _activate(
      id: _pool[nextIndex].id,
      body: _pool[nextIndex].body,
      index: nextIndex,
      attempt: 1,
      grade: snapshot.grade,
      lang: snapshot.lang,
    );
  }
}

final openPracticeControllerProvider = StateNotifierProvider.family<
    OpenPracticeController, OpenPracticeState, String>(
  (ref, lessonId) => OpenPracticeController(ref, lessonId),
);
