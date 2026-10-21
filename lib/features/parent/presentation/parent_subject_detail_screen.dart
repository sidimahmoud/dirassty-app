import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chapter.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/lesson_progress_summary.dart';
import '../../../core/models/student.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/theme/subject_colors.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../application/parent_providers.dart';

/// A single child's lesson-by-lesson breakdown for one subject — opened
/// from the mastery list / "Détail leçon par leçon" on
/// [ChildProgressScreen]. Two separate facts per lesson (finished the
/// lesson vs. actually did its exercises), which one blended mastery %
/// would hide. No handoff mock of its own; built from the Dirassty
/// components (DirasstyCard, DirasstyProgressBar, chapter rows as on
/// SubjectDetail.dc.html).
class ParentSubjectDetailScreen extends ConsumerWidget {
  const ParentSubjectDetailScreen({
    required this.studentId,
    required this.subjectKey,
    super.key,
  });

  static const String path = '/parent/child/:studentId/subject/:subjectKey';
  static const String name = 'parentSubjectDetail';

  final String studentId;
  final String subjectKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Student>> students =
        ref.watch(studentsByParentProvider);
    final Student? child =
        students.valueOrNull?.where((s) => s.id == studentId).firstOrNull;
    final String? dbLabel = child == null
        ? null
        : ref
            .watch(
              subjectsWithMasteryForStudentProvider(
                (
                  studentId: child.id,
                  country: child.country,
                  grade: child.grade,
                ),
              ),
            )
            .valueOrNull
            ?.where((s) => s.key == subjectKey)
            .firstOrNull
            ?.label;

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        title: Text(
          subjectDisplayName(
            subjectKey,
            isArabic: context.isArabicLocale,
            dbLabel: dbLabel,
          ),
        ),
      ),
      body: students.when(
        loading: () => const _Skeleton(),
        error: (_, __) => ErrorState(
          title: l10n.errGeneric,
          onRetry: () => ref.invalidate(studentsByParentProvider),
        ),
        data: (list) {
          final Student? student =
              list.where((s) => s.id == studentId).firstOrNull;
          if (student == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: l10n.childNotFound,
            );
          }
          return _Body(student: student, subjectKey: subjectKey);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.student, required this.subjectKey});

  final Student student;
  final String subjectKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({String country, int grade, String subjectKey}) chaptersArgs = (
      country: student.country,
      grade: student.grade,
      subjectKey: subjectKey,
    );
    final AsyncValue<List<Chapter>> chapters =
        ref.watch(chaptersForProvider(chaptersArgs));
    final AsyncValue<Map<String, LessonProgressSummary>> summary = ref.watch(
      lessonProgressSummaryProvider(
        (
          studentId: student.id,
          subjectKey: subjectKey,
          grade: student.grade,
        ),
      ),
    );

    return chapters.when(
      loading: () => const _Skeleton(),
      error: (_, __) => ErrorState(
        title: l10n.errGeneric,
        onRetry: () => ref.invalidate(chaptersForProvider(chaptersArgs)),
      ),
      data: (chapterList) {
        final List<CurriculumLesson> allLessons =
            chapterList.expand((c) => c.lessons).toList();
        if (allLessons.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: l10n.noContentYet,
          );
        }
        final Map<String, LessonProgressSummary> byLesson =
            summary.valueOrNull ?? const {};
        LessonProgressSummary of(CurriculumLesson l) =>
            byLesson[l.id] ?? LessonProgressSummary.none;
        final int completedCount = allLessons.where((l) => of(l).viewed).length;
        final int exercisedCount =
            allLessons.where((l) => of(l).exercisesDone).length;

        return ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen,
            DirasstySpace.sm,
            DirasstySpace.screen,
            DirasstySpace.xxl,
          ),
          children: [
            DirasstyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.lessonsInSubject(allLessons.length),
                    style: context.dirasstyType.subheading,
                  ),
                  const SizedBox(height: DirasstySpace.lg),
                  _SummaryRow(
                    label: l10n.lessonsCompleted,
                    count: completedCount,
                    total: allLessons.length,
                    color: DirasstyColors.teal,
                  ),
                  const SizedBox(height: DirasstySpace.md),
                  _SummaryRow(
                    label: l10n.withExercisesDone,
                    count: exercisedCount,
                    total: allLessons.length,
                    color: DirasstyColors.gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DirasstySpace.xl),
            for (final Chapter chapter in chapterList) ...[
              _ChapterCard(chapter: chapter, summaryOf: of),
              const SizedBox(height: DirasstySpace.md),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: type.bodySmall)),
            Text(
              '$count/$total',
              textDirection: TextDirection.ltr,
              style: type.label.copyWith(
                color: DirasstyColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: DirasstySpace.xs),
        DirasstyProgressBar(value: total > 0 ? count / total : 0, color: color),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.summaryOf});

  final Chapter chapter;
  final LessonProgressSummary Function(CurriculumLesson) summaryOf;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DirasstyCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: chapter.num == 1,
          shape: const Border(),
          title: Text(
            l10n.chapterTitle(chapter.num, chapter.title),
            style: context.dirasstyType.subheading.copyWith(fontSize: 14),
          ),
          children: [
            for (final CurriculumLesson lesson in chapter.lessons) ...[
              const Divider(height: 1),
              _LessonRow(lesson: lesson, summary: summaryOf(lesson)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.summary});

  final CurriculumLesson lesson;
  final LessonProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final (IconData icon, Color color, String label) = summary.exercisesDone
        ? (
            Icons.verified_rounded,
            DirasstyColors.teal,
            l10n.lessonStatusExercised(
              (summary.mastery * 100).round(),
              summary.attempts,
            ),
          )
        : summary.viewed
            ? (
                Icons.check_circle_outline_rounded,
                DirasstyColors.teal,
                l10n.lessonStatusViewed,
              )
            : (
                Icons.radio_button_unchecked_rounded,
                DirasstyColors.idle,
                l10n.lessonStatusNotStarted,
              );

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DirasstySpace.lg,
        vertical: DirasstySpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lesson.lessonNum}. ${lesson.lessonTitle}',
                  style: type.subheading.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: type.label.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Skeleton(height: 130, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 56, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 56, radius: DirasstyRadius.card),
      ],
    );
  }
}
