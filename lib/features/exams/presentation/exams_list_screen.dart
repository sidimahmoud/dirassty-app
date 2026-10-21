import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/exam.dart';
import '../../../core/models/student.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/widgets/student_tab_bar.dart';
import '../../student/application/student_providers.dart';
import '../application/exam_providers.dart';
import 'exam_intro_screen.dart';
import 'exam_session_screen.dart';

enum _ExamFilter { upcoming, past }

/// Exams tab (tab 3): the next exam as an ink hero card, À venir / Passés
/// filter, "Cette semaine" (open exams) and "Résultats récents" (completed
/// and missed ones).
///
/// design_handoff ExamsList.dc.html · DESIGN_SPEC §4 "Exams".
class ExamsListScreen extends ConsumerStatefulWidget {
  const ExamsListScreen({super.key});

  static const String path = '/exams';
  static const String name = 'exams';

  @override
  ConsumerState<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends ConsumerState<ExamsListScreen> {
  _ExamFilter _filter = _ExamFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;
    final AsyncValue<List<Exam>>? exams =
        student == null ? null : ref.watch(examsByStudentProvider(student.id));

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      bottomNavigationBar: const StudentTabBar(currentIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (student != null) {
              ref.invalidate(examsByStudentProvider(student.id));
            }
          },
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.screen,
              DirasstySpace.xl,
              DirasstySpace.screen,
              DirasstySpace.xl,
            ),
            children: [
              Text(l10n.exams, style: type.title),
              const SizedBox(height: DirasstySpace.xs),
              Text(l10n.examsBody, style: type.bodySmall),
              const SizedBox(height: DirasstySpace.lg),
              if (exams == null)
                const _ListSkeleton()
              else
                exams.when(
                  loading: () => const _ListSkeleton(),
                  error: (_, __) => ErrorState(
                    title: l10n.examsLoadError,
                    onRetry: () =>
                        ref.invalidate(examsByStudentProvider(student!.id)),
                  ),
                  data: (list) => _buildContent(context, l10n, list),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<Exam> all,
  ) {
    final DirasstyType type = context.dirasstyType;
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    bool isThisWeek(Exam e) =>
        e.weekStart.year == monday.year &&
        e.weekStart.month == monday.month &&
        e.weekStart.day == monday.day;
    int order(ExamStatus s) => switch (s) {
          ExamStatus.available => 0,
          ExamStatus.scheduled => 1,
          ExamStatus.completed => 2,
          ExamStatus.missed => 3,
        };

    // This week: one exam per subject — the checklist the student works
    // through (DESIGN: "one exam per subject, every week").
    final List<Exam> week = all.where(isThisWeek).toList()
      ..sort((a, b) {
        final int byStatus = order(a.status).compareTo(order(b.status));
        return byStatus != 0
            ? byStatus
            : a.availableFrom.compareTo(b.availableFrom);
      });
    final List<Exam> past = all
        .where(
          (e) =>
              !isThisWeek(e) &&
              (e.status == ExamStatus.completed ||
                  e.status == ExamStatus.missed),
        )
        .toList()
      ..sort(
        (a, b) =>
            (b.completedAt ?? b.dueAt).compareTo(a.completedAt ?? a.dueAt),
      );
    final Exam? next =
        week.where((e) => e.status == ExamStatus.available).firstOrNull;
    final int done = week.where((e) => e.status == ExamStatus.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (next != null) ...[
          _HeroCard(exam: next),
          const SizedBox(height: DirasstySpace.lg),
        ],
        Wrap(
          spacing: DirasstySpace.sm,
          children: [
            for (final (_ExamFilter f, String label) in [
              (_ExamFilter.upcoming, l10n.thisWeek),
              (_ExamFilter.past, l10n.filterPast),
            ])
              DirasstyChip(
                label: label,
                variant: _filter == f
                    ? DirasstyChipVariant.selected
                    : DirasstyChipVariant.neutral,
                onTap: () => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: DirasstySpace.lg),
        if (_filter == _ExamFilter.upcoming) ...[
          if (week.isEmpty)
            EmptyState(
              icon: Icons.event_available_rounded,
              title: l10n.noExamsThisWeek,
              message: l10n.noExamsBody,
            )
          else ...[
            DirasstyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.examsOfTheWeek,
                          style: type.subheading,
                        ),
                      ),
                      Text(
                        '$done/${week.length}',
                        textDirection: TextDirection.ltr,
                        style: type.subheading.copyWith(
                          fontFamily: 'Inter',
                          color: DirasstyColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DirasstySpace.sm),
                  DirasstyProgressBar(value: done / week.length),
                  const SizedBox(height: DirasstySpace.sm),
                  Text(
                    done == week.length
                        ? l10n.weekExamsDone
                        : l10n.weekProgress(done, week.length),
                    style: type.label.copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DirasstySpace.md),
            _ExamGroup(exams: week),
          ],
        ] else ...[
          if (past.isEmpty)
            EmptyState(icon: Icons.history_rounded, title: l10n.noPastExams)
          else
            _ExamGroup(exams: past),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final int days = DirasstyDates.daysFromToday(exam.dueAt);

    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      decoration: const BoxDecoration(
        color: DirasstyColors.ink,
        borderRadius: DirasstyRadius.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DirasstyColors.gold,
                  borderRadius: DirasstyRadius.pillR,
                ),
                child: Text(
                  DirasstyDates.weekdayTime(exam.dueAt, lang),
                  style: type.label.copyWith(
                    color: DirasstyColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                days <= 0
                    ? l10n.today
                    : (days == 1 ? l10n.tomorrow : l10n.inDays(days)),
                style:
                    type.label.copyWith(color: DirasstyColors.textOnDarkMuted),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.md),
          Text(
            exam.subject.label,
            style: type.titleSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.questionsCount(exam.totalQuestions),
            style: type.label.copyWith(
              color: DirasstyColors.textOnDarkMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: DirasstySpace.lg),
          DirasstyButton(
            label: l10n.seeExam,
            variant: DirasstyButtonVariant.gold,
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

class _ExamGroup extends StatelessWidget {
  const _ExamGroup({required this.exams});

  final List<Exam> exams;

  @override
  Widget build(BuildContext context) {
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
            for (final (int i, Exam e) in exams.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _ExamRow(exam: e),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final bool completed = exam.status == ExamStatus.completed;
    final bool missed = exam.status == ExamStatus.missed;
    final bool open = exam.status == ExamStatus.available;
    final bool scheduled = exam.status == ExamStatus.scheduled;

    return InkWell(
      onTap: missed || scheduled
          ? null
          : () => completed
              ? context.push(ExamSessionScreen.pathFor(exam.id))
              : context.pushNamed(
                  ExamIntroScreen.name,
                  pathParameters: {'examId': exam.id},
                  extra: exam,
                ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DirasstySpace.lg,
            vertical: DirasstySpace.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: open ? DirasstyColors.tealTint : DirasstyColors.track,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  exam.subject.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.subject.label, style: type.subheading),
                    const SizedBox(height: 2),
                    Text(
                      '${DirasstyDates.dayMonthYear(exam.completedAt ?? exam.dueAt, lang)} · ${l10n.questionsCount(exam.totalQuestions)}',
                      style: type.label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (open)
                DirasstyChip(
                  label: l10n.examToDo,
                  variant: DirasstyChipVariant.gold,
                  dense: true,
                )
              else if (scheduled)
                DirasstyChip(
                  label: l10n.availableOn(
                    DirasstyDates.weekday(exam.availableFrom, lang),
                  ),
                  dense: true,
                )
              else if (missed)
                DirasstyChip(
                  label: l10n.missed,
                  variant: DirasstyChipVariant.red,
                  dense: true,
                )
              else
                Text(
                  '${exam.correctCount ?? 0}/${exam.totalQuestions}',
                  textDirection: TextDirection.ltr,
                  style: type.subheading.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: (exam.scoreRatio ?? 0) >= 0.75
                        ? DirasstyColors.teal
                        : DirasstyColors.ink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Skeleton(height: 170, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.lg),
        Skeleton(height: 64, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 64, radius: DirasstyRadius.card),
      ],
    );
  }
}
