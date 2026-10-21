import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/gamification/gamification.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/models/exam.dart';
import '../../../core/models/grade.dart';
import '../../../core/models/student.dart';
import '../../../core/models/student_stats.dart';
import '../../../core/models/subject.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../courses/application/courses_providers.dart';
import '../../courses/presentation/courses_screen.dart';
import '../../courses/presentation/subject_detail_screen.dart';
import '../../exams/application/exam_providers.dart';
import '../../exams/presentation/exam_intro_screen.dart';
import '../../homework/presentation/homework_helper_screen.dart';
import '../../profile/presentation/downloads_screen.dart';
import '../../progress/application/progress_providers.dart';
import '../../student/application/student_providers.dart';
import 'widgets/student_tab_bar.dart';

/// Student home (tab 1): greeting + streak, level card with XP bar,
/// "Ma semaine" stats, subject grid, the next weekly exam, and the
/// Homework Helper card.
///
/// States: skeleton while loading; when the profile can't load (usually
/// no connection) the offline banner + retry, with the downloads one tap
/// away; a failing subjects fetch shows an inline ErrorState without
/// hiding the rest.
///
/// Deviations from StudentHome.dc.html (data gaps, TODO(api)): no
/// notifications bell (no in-app inbox yet); no level title under
/// "Niveau N"; the active-days tile shows the count without the per-day
/// bars (stats only carry a count, not which days).
///
/// design_handoff StudentHome.dc.html / StudentHomeAR.dc.html /
/// HomeStates.dc.html · DESIGN_SPEC §4 "Home".
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  static const String path = '/home';
  static const String name = 'studentHome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Student> student = ref.watch(currentStudentProvider);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      bottomNavigationBar: const StudentTabBar(currentIndex: 0),
      body: student.when(
        loading: () => const _HomeSkeleton(),
        error: (error, _) => _HomeOffline(
          onRetry: () {
            // The account check itself may be what failed: retry it too.
            if (ref.read(appAuthStateProvider).hasError) {
              ref.invalidate(appAuthStateProvider);
            }
            ref.invalidate(currentStudentProvider);
          },
        ),
        data: (s) => _HomeBody(student: s),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<StudentStats> stats =
        ref.watch(studentStatsProvider(student.id));
    final AsyncValue<List<Subject>> subjects =
        ref.watch(subjectsWithMasteryProvider);
    final Exam? nextExam =
        _nextExam(ref.watch(examsByStudentProvider(student.id)).valueOrNull);

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.refresh(currentStudentProvider.future),
        ref.refresh(studentStatsProvider(student.id).future),
        ref.refresh(subjectsWithMasteryProvider.future),
        ref.refresh(examsByStudentProvider(student.id).future),
      ]),
      child: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen,
          MediaQuery.paddingOf(context).top + DirasstySpace.lg,
          DirasstySpace.screen,
          DirasstySpace.xl,
        ),
        children: [
          _Header(student: student),
          const SizedBox(height: DirasstySpace.xl),
          _LevelCard(xpTotal: student.xpTotal),
          const SizedBox(height: DirasstySpace.xl),
          _SectionTitle(
            title: l10n.mySubjects,
            trailing: TextButton(
              onPressed: () => context.go(CoursesScreen.path),
              child: Text(l10n.seeAll),
            ),
          ),
          const SizedBox(height: DirasstySpace.xs),
          subjects.when(
            loading: () => const _GridSkeleton(height: 80),
            error: (_, __) => ErrorState(
              onRetry: () => ref.invalidate(subjectsWithMasteryProvider),
            ),
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: l10n.noSubjects,
                  )
                : SubjectGrid(subjects: list.take(4).toList()),
          ),
          const SizedBox(height: DirasstySpace.xl),
          _SectionTitle(
            title: l10n.myWeek,
            trailing: Text(
              DirasstyDates.dayMonthRange(
                DateTime.now().subtract(const Duration(days: 6)),
                DateTime.now(),
                Localizations.localeOf(context).languageCode,
              ),
              style: type.label.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(height: DirasstySpace.md),
          stats.when(
            loading: () => const _GridSkeleton(height: 96),
            error: (_, __) => ErrorState(
              onRetry: () => ref.invalidate(studentStatsProvider(student.id)),
            ),
            data: (s) => _WeekStats(week: s.week),
          ),
          if (nextExam != null) ...[
            const SizedBox(height: DirasstySpace.xl),
            _ExamCard(exam: nextExam),
          ],
          const SizedBox(height: DirasstySpace.lg),
          const _HelperCard(),
        ],
      ),
    );
  }

  /// The soonest exam the student can still take.
  static Exam? _nextExam(List<Exam>? exams) {
    final List<Exam> open = (exams ?? const <Exam>[])
        .where((e) => e.status == ExamStatus.available)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return open.isEmpty ? null : open.first;
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String firstName = student.name.trim().split(RegExp(r'\s+')).first;
    final String cycle = switch (gradeCycle(student.grade)) {
      GradeCycle.primaire => l10n.cyclePrimary,
      GradeCycle.college => l10n.cycleMiddle,
      GradeCycle.lycee => l10n.cycleHigh,
    };

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: DirasstyColors.tealTint,
            shape: BoxShape.circle,
          ),
          child: Text(
            firstName.isEmpty ? '?' : firstName.characters.first.toUpperCase(),
            style: type.heading.copyWith(
              color: DirasstyColors.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: DirasstySpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hello(firstName),
                style: type.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${gradeName(ref, student.grade)} · $cycle',
                style: type.label,
              ),
            ],
          ),
        ),
        StreakBadge(
          days: student.streak,
          semanticLabel: l10n.streakDays(student.streak),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.xpTotal});

  final int xpTotal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final int level = levelFromXp(xpTotal);
    final int next = nextLevelXp(xpTotal);
    final int remaining = (next - xpTotal).clamp(0, next);

    return DirasstyCard(
      variant: DirasstyCardVariant.shadow,
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LevelBadge(level: level, semanticLabel: l10n.level(level)),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.level(level), style: type.subheading)),
              Text(
                l10n.xpOfTotal(xpTotal, next),
                style: type.subheading.copyWith(fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.md),
          XpBar(value: levelProgress(xpTotal)),
          const SizedBox(height: DirasstySpace.sm),
          Text(
            remaining == 0
                ? l10n.level(level)
                : l10n.xpToNext(remaining, level + 1),
            style: type.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _WeekStats extends StatelessWidget {
  const _WeekStats({required this.week});

  final PeriodStats week;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int minutes = week.minutesOnApp;
    final String time = minutes >= 60
        ? l10n.hoursMinutes(
            minutes ~/ 60,
            (minutes % 60).toString().padLeft(2, '0'),
          )
        : l10n.minutesShort(minutes);
    final List<Widget> tiles = [
      StatTile(
        value: '${(week.correctRate * 100).round()} %',
        label: l10n.correctAnswers,
        emphasize: true,
      ),
      StatTile(value: '${week.exercisesDone}', label: l10n.exercisesDone),
      StatTile(
        value: '${week.daysActive}/${week.periodDays}',
        label: l10n.activeDays,
      ),
      StatTile(value: time, label: l10n.studyTime),
    ];
    return _TwoColumnGrid(children: tiles);
  }
}

/// Subject cards two per row (one column when very narrow at large text
/// sizes — DESIGN_SPEC §7), ring colors alternating teal / ink. Shared
/// with the subjects tab.
class SubjectGrid extends StatelessWidget {
  const SubjectGrid({required this.subjects, super.key});

  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _TwoColumnGrid(
      children: [
        for (final (int i, Subject s) in subjects.indexed)
          SubjectCard(
            name: s.label,
            icon: s.icon,
            lessonsLabel: s.totalLessons == null
                ? ''
                : l10n.lessonsCount(s.totalLessons!),
            mastery: s.mastery ?? 0,
            ringColor: i.isEven ? DirasstyColors.teal : DirasstyColors.ink,
            onTap: () => context.pushNamed(
              SubjectDetailScreen.name,
              pathParameters: {'subjectKey': s.key},
            ),
          ),
      ],
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool singleColumn = context.useSingleColumn;
    final int columns =
        singleColumn ? 1 : adaptiveGridColumns(context).clamp(2, 4);
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: i + j < children.length
                      ? children[i + j]
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: DirasstySpace.md),
          rows[i],
        ],
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final int days = DirasstyDates.daysFromToday(exam.dueAt);
    final String when = days <= 0
        ? l10n.today
        : days == 1
            ? l10n.tomorrow
            : l10n.inDays(days);

    return DirasstyCard(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: DirasstyColors.tealTint,
                  borderRadius: DirasstyRadius.cardR,
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: DirasstyColors.teal,
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.weeklyExam, style: type.label),
                    Text(exam.subject.label, style: type.subheading),
                  ],
                ),
              ),
              DirasstyChip(
                label: when,
                variant: DirasstyChipVariant.gold,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.md),
          Wrap(
            spacing: DirasstySpace.lg,
            children: [
              Text(
                DirasstyDates.weekdayTime(
                  exam.dueAt,
                  Localizations.localeOf(context).languageCode,
                ),
                style: type.bodySmall,
              ),
              Text(
                l10n.questionsCount(exam.totalQuestions),
                style: type.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.lg),
          DirasstyButton(
            label: l10n.prepare,
            variant: DirasstyButtonVariant.secondary,
            compact: true,
            onPressed: () => context.pushNamed(
              ExamIntroScreen.name,
              pathParameters: {'examId': exam.id},
              extra: exam,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  const _HelperCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Material(
      color: DirasstyColors.teal,
      borderRadius: DirasstyRadius.cardR,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(HomeworkHelperScreen.path),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.photo_camera_rounded, color: Colors.white),
              ),
              const SizedBox(width: DirasstySpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeworkHelper,
                      style: type.subheading.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: DirasstySpace.xs),
                    Text(
                      l10n.homeworkHelperSub,
                      style: type.bodySmall
                          .copyWith(color: DirasstyColors.textOnDarkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.dirasstyType.heading)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.screen,
        MediaQuery.paddingOf(context).top + DirasstySpace.lg,
        DirasstySpace.screen,
        DirasstySpace.xl,
      ),
      children: const [
        Row(
          children: [
            Skeleton(width: 48, height: 48, radius: 24),
            SizedBox(width: DirasstySpace.md),
            Expanded(child: Skeleton(height: 20)),
          ],
        ),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 112, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        _GridSkeleton(height: 96),
        SizedBox(height: DirasstySpace.xl),
        _GridSkeleton(height: 80),
      ],
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    Widget row() => Row(
          children: [
            Expanded(
              child: Skeleton(height: height, radius: DirasstyRadius.card),
            ),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Skeleton(height: height, radius: DirasstyRadius.card),
            ),
          ],
        );
    return Column(
      children: [row(), const SizedBox(height: DirasstySpace.md), row()],
    );
  }
}

/// Profile couldn't load — almost always no connection. Downloads still
/// work offline, so they stay one tap away.
class _HomeOffline extends StatelessWidget {
  const _HomeOffline({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: [
        ColoredBox(
          color: DirasstyColors.ink,
          child: SafeArea(
            bottom: false,
            child:
                OfflineBanner(onSee: () => context.push(DownloadsScreen.path)),
          ),
        ),
        Expanded(
          child: Center(
            child: ErrorState(
              title: l10n.profileLoadError,
              onRetry: onRetry,
            ),
          ),
        ),
      ],
    );
  }
}
