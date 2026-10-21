import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/exam.dart';
import '../../../../core/text/dirassty_dates.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exams/application/exam_providers.dart';
import '../child_exam_history_screen.dart';

/// "Examens de la semaine" on a child's progress page: X/Y done and one
/// line per subject — Fait (score), À faire, Dès {jour}, Manqué. Tapping
/// opens the full exam history. Hidden when the week has no exam yet.
class WeekExamsCard extends ConsumerWidget {
  const WeekExamsCard({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final List<Exam> all =
        ref.watch(examsByStudentProvider(studentId)).valueOrNull ?? const [];
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final List<Exam> week = all
        .where(
          (e) =>
              e.weekStart.year == monday.year &&
              e.weekStart.month == monday.month &&
              e.weekStart.day == monday.day,
        )
        .toList()
      ..sort((a, b) => a.subject.label.compareTo(b.subject.label));
    if (week.isEmpty) return const SizedBox.shrink();
    final int done = week.where((e) => e.status == ExamStatus.completed).length;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: DirasstySpace.lg),
      child: DirasstyCard(
        variant: DirasstyCardVariant.shadow,
        onTap: () => context.pushNamed(
          ChildExamHistoryScreen.name,
          pathParameters: {'studentId': studentId},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  size: 20,
                  color: DirasstyColors.teal,
                ),
                const SizedBox(width: DirasstySpace.sm),
                Expanded(
                  child: Text(
                    l10n.examsOfTheWeek,
                    style: type.subheading.copyWith(fontSize: 14),
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
            const SizedBox(height: DirasstySpace.md),
            for (final Exam e in week)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 6),
                child: Row(
                  children: [
                    Text(e.subject.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: DirasstySpace.sm),
                    Expanded(
                      child: Text(e.subject.label, style: type.bodySmall),
                    ),
                    switch (e.status) {
                      ExamStatus.completed => DirasstyChip(
                          label: '${e.correctCount ?? 0}/${e.totalQuestions}',
                          variant: DirasstyChipVariant.teal,
                          dense: true,
                        ),
                      ExamStatus.available => DirasstyChip(
                          label: l10n.examToDo,
                          variant: DirasstyChipVariant.gold,
                          dense: true,
                        ),
                      ExamStatus.scheduled => DirasstyChip(
                          label: l10n.availableOn(
                            DirasstyDates.weekday(e.availableFrom, lang),
                          ),
                          dense: true,
                        ),
                      ExamStatus.missed => DirasstyChip(
                          label: l10n.missed,
                          variant: DirasstyChipVariant.red,
                          dense: true,
                        ),
                    },
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
