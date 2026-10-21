import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/chapter.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/lesson_progress_summary.dart';
import '../../../core/models/student.dart';
import '../../../core/offline/offline_videos_controller.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/theme/subject_colors.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import '../application/courses_providers.dart';

/// A lesson counts as mastered from this mastery ratio up (same bar the
/// spaced-repetition review schedule uses, see ProgressRepository).
const double kLessonMasteredAt = 0.8;

enum _Filter { all, toReview, offline }

/// A subject's chapters and lessons: header mastery ring, filter chips
/// (Toutes / À revoir / Hors ligne), then chapter cards — the chapter
/// holding the next lesson to work on starts expanded, the others open on
/// tap. No lesson is ever locked. Tapping a lesson opens the lesson
/// viewer, whose resume screen offers the QCM / practice / summary for
/// lessons already read.
///
/// design_handoff SubjectDetail.dc.html · DESIGN_SPEC §4 "Subject detail".
class SubjectDetailScreen extends ConsumerStatefulWidget {
  const SubjectDetailScreen({required this.subjectKey, super.key});

  static const String path = '/courses/:subjectKey';
  static const String name = 'subjectDetail';

  final String subjectKey;

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  _Filter _filter = _Filter.all;

  /// Chapters the student opened/closed by hand; null until the first
  /// tap, so the default (the current chapter) applies.
  Set<int>? _expanded;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Same (cached) list the Subjects tab shows — carries each subject's
    // stored label.
    final String? dbLabel = ref
        .watch(subjectsWithMasteryProvider)
        .valueOrNull
        ?.where((s) => s.key == widget.subjectKey)
        .firstOrNull
        ?.label;
    final String subjectName = subjectDisplayName(
      widget.subjectKey,
      isArabic: context.isArabicLocale,
      dbLabel: dbLabel,
    );
    final AsyncValue<List<Chapter>> chapters =
        ref.watch(chaptersProvider(widget.subjectKey));
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(l10n.tabSubjects)),
      body: chapters.when(
        loading: () => const _Skeleton(),
        error: (_, __) => Center(
          child: ErrorState(
            title: l10n.subjectLoadError,
            onRetry: () => ref.invalidate(chaptersProvider(widget.subjectKey)),
          ),
        ),
        data: (chapterList) {
          if (chapterList.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.hourglass_empty_rounded,
                title: l10n.comingSoon,
                message: l10n.comingSoonBody,
              ),
            );
          }
          if (student == null) return const _Skeleton();
          return _buildContent(
            context,
            l10n,
            subjectName,
            chapterList,
            student,
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String subjectName,
    List<Chapter> chapterList,
    Student student,
  ) {
    final DirasstyType type = context.dirasstyType;
    final ({String studentId, String subjectKey, int grade}) args = (
      studentId: student.id,
      subjectKey: widget.subjectKey,
      grade: student.grade
    );
    final Map<String, double> mastery =
        ref.watch(lessonMasteryMapProvider(args)).valueOrNull ?? {};
    final Set<String> viewed =
        ref.watch(viewedLessonIdsProvider(student.id)).valueOrNull ?? {};
    final Map<String, LessonProgressSummary> summary =
        ref.watch(lessonProgressSummaryProvider(args)).valueOrNull ?? {};
    final Set<String> offline =
        ref.watch(offlineVideosControllerProvider).offlineLessonIds;

    final List<CurriculumLesson> all =
        chapterList.expand((c) => c.lessons).toList();
    final int masteredCount =
        all.where((l) => (mastery[l.id] ?? 0) >= kLessonMasteredAt).length;
    final double overall = all.isEmpty
        ? 0
        : all.fold(0.0, (sum, l) => sum + (mastery[l.id] ?? 0)) / all.length;

    // The next lesson worth working on: first in order not both read and
    // quizzed (not gated on mastery — a read + quizzed lesson is done for
    // continuation purposes, retrying stays reachable). Its chapter is
    // the one expanded by default.
    final CurriculumLesson? next = all.cast<CurriculumLesson?>().firstWhere(
          (l) => !(viewed.contains(l!.id) &&
              (summary[l.id]?.exercisesDone ?? false)),
          orElse: () => null,
        );
    final Set<int> expanded =
        _expanded ?? {next?.chapterNum ?? chapterList.first.num};

    bool visible(CurriculumLesson l) => switch (_filter) {
          _Filter.all => true,
          _Filter.toReview =>
            viewed.contains(l.id) && (mastery[l.id] ?? 0) < kLessonMasteredAt,
          _Filter.offline => offline.contains(l.id),
        };
    final List<Chapter> shown = [
      for (final Chapter c in chapterList)
        if (c.lessons.any(visible)) c,
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(chaptersProvider(widget.subjectKey));
        ref.invalidate(lessonMasteryMapProvider(args));
        ref.invalidate(lessonProgressSummaryProvider(args));
      },
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen,
          DirasstySpace.sm,
          DirasstySpace.screen,
          DirasstySpace.xl,
        ),
        children: [
          Row(
            children: [
              MasteryRing(value: overall, size: 80, stroke: 7),
              const SizedBox(width: DirasstySpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subjectName, style: type.title),
                    const SizedBox(height: DirasstySpace.xs),
                    Text(
                      '${gradeName(ref, student.grade)} · ${l10n.chaptersCount(chapterList.length)} · ${l10n.lessonsCount(all.length)}',
                      style: type.bodySmall,
                    ),
                    const SizedBox(height: DirasstySpace.xs),
                    Text(
                      l10n.masteredLessonsCount(masteredCount),
                      style: type.label.copyWith(color: DirasstyColors.teal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.screen),
          Wrap(
            spacing: DirasstySpace.sm,
            children: [
              for (final (_Filter f, String label, IconData? icon) in [
                (_Filter.all, l10n.filterAll, null),
                (_Filter.toReview, l10n.filterToReview, null),
                (
                  _Filter.offline,
                  l10n.filterOffline,
                  Icons.download_done_rounded
                ),
              ])
                DirasstyChip(
                  label: label,
                  icon: icon,
                  variant: _filter == f
                      ? DirasstyChipVariant.selected
                      : DirasstyChipVariant.neutral,
                  onTap: () => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: DirasstySpace.lg),
          if (shown.isEmpty)
            _filter == _Filter.offline
                ? EmptyState(
                    icon: Icons.download_rounded,
                    title: l10n.noOfflineLessons,
                    message: l10n.noOfflineLessonsBody,
                  )
                : EmptyState(
                    icon: Icons.check_rounded,
                    title: l10n.noLessonsToReview,
                    message: l10n.noLessonsToReviewBody,
                  )
          else
            for (final (int i, Chapter chapter) in shown.indexed) ...[
              if (i > 0) const SizedBox(height: DirasstySpace.md),
              _ChapterCard(
                chapter: chapter,
                lessons: chapter.lessons.where(visible).toList(),
                mastery: mastery,
                viewed: viewed,
                offline: offline,
                // A filter narrows the list — show its matches directly.
                expanded:
                    _filter != _Filter.all || expanded.contains(chapter.num),
                onToggle: () => setState(() {
                  final Set<int> next = {...expanded};
                  next.contains(chapter.num)
                      ? next.remove(chapter.num)
                      : next.add(chapter.num);
                  _expanded = next;
                }),
              ),
            ],
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.lessons,
    required this.mastery,
    required this.viewed,
    required this.offline,
    required this.expanded,
    required this.onToggle,
  });

  final Chapter chapter;
  final List<CurriculumLesson> lessons;
  final Map<String, double> mastery;
  final Set<String> viewed;
  final Set<String> offline;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final double ratio = chapter.lessons.isEmpty
        ? 0
        : chapter.lessons.fold(0.0, (sum, l) => sum + (mastery[l.id] ?? 0)) /
            chapter.lessons.length;
    final int mastered = chapter.lessons
        .where((l) => (mastery[l.id] ?? 0) >= kLessonMasteredAt)
        .length;
    final Color accent = expanded ? DirasstyColors.teal : DirasstyColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: expanded
                            ? DirasstyColors.tealTint
                            : DirasstyColors.track,
                        borderRadius: DirasstyRadius.smallR,
                      ),
                      child: Text(
                        '${chapter.num}',
                        style: type.subheading.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: expanded
                              ? DirasstyColors.teal
                              : DirasstyColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: DirasstySpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapter.title,
                                  style: type.subheading,
                                ),
                              ),
                              Text(
                                '${(ratio * 100).round()} %',
                                style: type.subheading.copyWith(
                                  fontSize: 14,
                                  color: expanded
                                      ? DirasstyColors.teal
                                      : DirasstyColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DirasstyProgressBar(
                            value: ratio,
                            color: accent,
                            height: 6,
                          ),
                          if (!expanded) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.chapterMeta(
                                chapter.lessons.length,
                                mastered,
                              ),
                              style: type.label
                                  .copyWith(fontWeight: FontWeight.w400),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              for (final CurriculumLesson lesson in lessons) ...[
                const Divider(height: 1),
                _LessonRow(
                  lesson: lesson,
                  mastery: mastery[lesson.id] ?? 0,
                  viewed: viewed.contains(lesson.id),
                  offline: offline.contains(lesson.id),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.mastery,
    required this.viewed,
    required this.offline,
  });

  final CurriculumLesson lesson;
  final double mastery;
  final bool viewed;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool mastered = mastery >= kLessonMasteredAt;
    final String status = mastered
        ? l10n.statusMastered
        : viewed
            ? l10n.statusViewed
            : l10n.statusNotStarted;
    final String meta = viewed || mastery > 0
        ? '$status · ${(mastery * 100).round()} %'
        : status;

    return InkWell(
      onTap: () => context.push('/lesson/${lesson.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DirasstySpace.lg,
            vertical: DirasstySpace.md,
          ),
          child: Row(
            children: [
              _StatusIcon(mastered: mastered, viewed: viewed),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.lessonTitle,
                      style: type.subheading
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: type.label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (offline)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: DirasstySpace.sm),
                  child: Icon(
                    Icons.download_done_rounded,
                    size: 20,
                    color: DirasstyColors.teal,
                    semanticLabel: l10n.statusDownloaded,
                  ),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DirasstyColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled teal check = mastered, ink ring with a dot = viewed, grey ring
/// = not started (DESIGN_SPEC §4 "Subject detail").
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.mastered, required this.viewed});

  final bool mastered;
  final bool viewed;

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: DirasstyColors.teal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: viewed ? DirasstyColors.ink : DirasstyColors.idle,
          width: viewed ? 2.5 : 2,
        ),
      ),
      child: viewed
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: DirasstyColors.ink,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Row(
          children: [
            Skeleton(width: 80, height: 80, radius: 40),
            SizedBox(width: DirasstySpace.lg),
            Expanded(child: Skeleton(height: 48)),
          ],
        ),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 220, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 84, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 84, radius: DirasstyRadius.card),
      ],
    );
  }
}
