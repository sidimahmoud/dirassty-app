import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lesson_progress_summary.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/subject_mastery.dart';
import '../../auth/application/auth_providers.dart';
import '../data/progress_repository.dart';

final Provider<ProgressRepository> progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(supabaseClientProvider)),
);

typedef SubjectMasteryArgs = ({String studentId, String subjectKey, int grade});

/// Family-keyed so the home screen and courses screen (which both need
/// every subject's mastery) share the exact same cached fetch instead of
/// each re-querying.
final subjectMasteryProvider =
    FutureProvider.family<SubjectMastery, SubjectMasteryArgs>((
  ref,
  args,
) {
  return ref.watch(progressRepositoryProvider).getSubjectMastery(
        studentId: args.studentId,
        subjectKey: args.subjectKey,
        grade: args.grade,
      );
});

final lessonMasteryMapProvider =
    FutureProvider.family<Map<String, double>, SubjectMasteryArgs>((ref, args) {
  return ref.watch(progressRepositoryProvider).getLessonMasteryMap(
        studentId: args.studentId,
        subjectKey: args.subjectKey,
        grade: args.grade,
      );
});

final studentStatsProvider = FutureProvider.family<StudentStats, String>((
  ref,
  studentId,
) {
  return ref.watch(progressRepositoryProvider).getStudentStats(studentId);
});

/// Every lesson id a student has viewed at least once — gates the
/// QCM/open-exercise shortcuts on the subject screen (see
/// SubjectDetailScreen/_LessonRow) and feeds the mastery floor in
/// [subjectMasteryProvider]/[lessonMasteryMapProvider].
final viewedLessonIdsProvider = FutureProvider.family<Set<String>, String>((
  ref,
  studentId,
) {
  return ref.watch(progressRepositoryProvider).getViewedLessonIds(studentId);
});

/// Every lesson id a student has completed an open-practice exercise for
/// at least once — used by the lesson resume screen to know whether
/// "redo the exercises" is actually offered (see
/// ProgressRepository.getOpenPracticeViewedLessonIds).
final openPracticeViewedLessonIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, studentId) {
  return ref
      .watch(progressRepositoryProvider)
      .getOpenPracticeViewedLessonIds(studentId);
});

/// Per-lesson viewed/exercised breakdown for one student's subject — see
/// ProgressRepository.getLessonProgressSummary. Powers the parent's
/// subject drill-down (ParentSubjectDetailScreen).
final lessonProgressSummaryProvider = FutureProvider.family<
    Map<String, LessonProgressSummary>, SubjectMasteryArgs>((
  ref,
  args,
) {
  return ref.watch(progressRepositoryProvider).getLessonProgressSummary(
        studentId: args.studentId,
        subjectKey: args.subjectKey,
        grade: args.grade,
      );
});
