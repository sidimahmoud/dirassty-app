import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chapter.dart';
import '../../../core/models/grade.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/student.dart';
import '../../../core/models/subject.dart';
import '../../auth/application/auth_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import '../data/curriculum_repository.dart';

final Provider<CurriculumRepository> curriculumRepositoryProvider = Provider(
  (ref) => CurriculumRepository(ref.watch(supabaseClientProvider)),
);

/// Grade IDs currently open for new registrations — watched by the
/// registration and add-child grade pickers so an admin deactivating a
/// grade (see the web admin's Curriculum page) actually removes it from
/// selection instead of just hiding it after the fact.
final FutureProvider<Set<int>> activeGradeIdsProvider = FutureProvider(
  (ref) async =>
      (await ref.watch(openGradesProvider.future)).map((g) => g.id).toSet(),
);

/// The class name the admin saved ("Terminale D") for [grade] — the
/// static code ("L3") until the list has loaded, or for a class that has
/// since been closed. Rebuilds the caller once the names arrive.
String gradeName(WidgetRef ref, int grade) =>
    ref
        .watch(openGradesProvider)
        .valueOrNull
        ?.where((g) => g.id == grade)
        .firstOrNull
        ?.label ??
    gradeCode(grade);

/// The open classes with their admin-saved names (one fetch, shared by
/// [activeGradeIdsProvider] and the pickers).
final FutureProvider<List<GradeOption>> openGradesProvider = FutureProvider(
  (ref) => ref.watch(curriculumRepositoryProvider).getOpenGrades(),
);

/// Every subject for the student's grade, each with its mastery %
/// attached. Watched by both the home screen and the courses screen —
/// one shared fetch, not two.
final FutureProvider<List<Subject>> subjectsWithMasteryProvider =
    FutureProvider((ref) async {
  final Student student = await ref.watch(currentStudentProvider.future);
  final CurriculumRepository curriculum = ref.watch(
    curriculumRepositoryProvider,
  );

  final List<Subject> subjects = await curriculum.getSubjectsWithContent(
    country: student.country,
    grade: student.grade,
  );

  final List<Subject> withMastery = await Future.wait(
    subjects.map((subject) async {
      final mastery = await ref.watch(
        subjectMasteryProvider((
          studentId: student.id,
          subjectKey: subject.key,
          grade: student.grade,
        )).future,
      );
      return subject.withMastery(
        mastery.mastery,
        totalLessons: mastery.totalLessons,
      );
    }),
  );
  return withMastery;
});

typedef _StudentSubjectsArgs = ({String studentId, String country, int grade});

/// Same shape as [subjectsWithMasteryProvider], but for an arbitrary
/// student rather than the logged-in one — used by the parent app to
/// show a specific child's subject mastery.
final subjectsWithMasteryForStudentProvider =
    FutureProvider.family<List<Subject>, _StudentSubjectsArgs>((
  ref,
  args,
) async {
  final CurriculumRepository curriculum =
      ref.watch(curriculumRepositoryProvider);
  final List<Subject> subjects = await curriculum.getSubjectsWithContent(
    country: args.country,
    grade: args.grade,
  );

  return Future.wait(
    subjects.map((subject) async {
      final mastery = await ref.watch(
        subjectMasteryProvider((
          studentId: args.studentId,
          subjectKey: subject.key,
          grade: args.grade,
        )).future,
      );
      return subject.withMastery(
        mastery.mastery,
        totalLessons: mastery.totalLessons,
      );
    }),
  );
});

final chaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  subjectKey,
) async {
  final Student student = await ref.watch(currentStudentProvider.future);
  return ref.watch(curriculumRepositoryProvider).getChapters(
        country: student.country,
        grade: student.grade,
        subjectKey: subjectKey,
      );
});

typedef _ChaptersForArgs = ({String country, int grade, String subjectKey});

/// Same as [chaptersProvider], but for an arbitrary (country, grade)
/// rather than the logged-in student — used by the parent app to show a
/// specific child's chapter/lesson list (see ParentSubjectDetailScreen).
final chaptersForProvider =
    FutureProvider.family<List<Chapter>, _ChaptersForArgs>((
  ref,
  args,
) {
  return ref.watch(curriculumRepositoryProvider).getChapters(
        country: args.country,
        grade: args.grade,
        subjectKey: args.subjectKey,
      );
});

final lessonByIdProvider = FutureProvider.family<CurriculumLesson, String>((
  ref,
  lessonId,
) {
  return ref.watch(curriculumRepositoryProvider).getLessonById(lessonId);
});
