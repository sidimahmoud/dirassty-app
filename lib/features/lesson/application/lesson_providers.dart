import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/explanation_body.dart';
import '../../../core/models/summary_body.dart';
import '../../../core/models/video_body.dart';
import '../../auth/application/auth_providers.dart';
import '../data/lesson_repository.dart';

final Provider<LessonRepository> lessonRepositoryProvider = Provider(
  (ref) => LessonRepository(ref.watch(supabaseClientProvider)),
);

final explanationProvider = FutureProvider.family<ExplanationBody?, String>((
  ref,
  lessonId,
) {
  return ref.watch(lessonRepositoryProvider).getExplanation(lessonId);
});

/// A lesson's explanation videos, oldest (first uploaded) first — usually
/// zero or one, but never assumed to be at most one anymore.
final lessonVideosProvider = FutureProvider.family<List<VideoBody>, String>((
  ref,
  lessonId,
) {
  return ref.watch(lessonRepositoryProvider).getVideos(lessonId);
});

/// The exercise "how to solve these" walkthrough videos — read by the QCM
/// and open-practice screens, not the lesson viewer.
final exerciseVideosProvider = FutureProvider.family<List<VideoBody>, String>((
  ref,
  lessonId,
) {
  return ref.watch(lessonRepositoryProvider).getExerciseVideos(lessonId);
});

/// Whether the lesson has a QCM / open exercises — where "continue" goes
/// at the end of the lesson flow.
final lessonPracticeProvider = FutureProvider.family<LessonPractice, String>((
  ref,
  lessonId,
) {
  return ref.watch(lessonRepositoryProvider).getPractice(lessonId);
});

/// The lesson's short revision-card summary — read by [LessonSummarySheet].
final lessonSummaryProvider = FutureProvider.family<SummaryBody?, String>((
  ref,
  lessonId,
) {
  return ref.watch(lessonRepositoryProvider).getSummary(lessonId);
});

/// Which lesson ids (out of the given, comma-joined list) have a verified
/// summary — powers the subject screen's "Résumé" shortcut chip, one
/// batched query per subject view instead of one per lesson row. Family
/// key is a comma-joined, sorted id list rather than a raw `List<String>`
/// so Riverpod can actually cache/compare it (`List` has no structural
/// `==`, so a fresh list built on every rebuild would never hit the
/// cache).
final lessonIdsWithSummaryProvider = FutureProvider.family<Set<String>, String>(
  (ref, joinedLessonIds) {
    final List<String> lessonIds =
        joinedLessonIds.isEmpty ? const [] : joinedLessonIds.split(',');
    return ref.watch(lessonRepositoryProvider).getLessonIdsWithSummary(
          lessonIds,
        );
  },
);
