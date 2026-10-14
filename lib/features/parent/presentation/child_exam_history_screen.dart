import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/exam.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../exams/application/exam_providers.dart';

/// The parent-facing weekly-exam record — read-only, grouped by week, so
/// a parent sees which subject/week combinations were completed (with
/// the score), are still open, or were missed (see 032_weekly_exams.sql
/// for why 'missed' is a permanent record). No handoff mock of its own;
/// styled like ExamsList.dc.html's "Résultats récents".
class ChildExamHistoryScreen extends ConsumerWidget {
  const ChildExamHistoryScreen({required this.studentId, super.key});

  static const String path = '/parent/child/:studentId/exams';
  static const String name = 'childExamHistory';

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final AsyncValue<List<Exam>> exams =
        ref.watch(examsByStudentProvider(studentId));

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(l10n.examHistory)),
      body: exams.when(
        loading: () => ListView(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
          children: const [
            Skeleton(height: 20, width: 160),
            SizedBox(height: DirasstySpace.md),
            Skeleton(height: 180, radius: DirasstyRadius.card),
          ],
        ),
        error: (_, __) => ErrorState(
          title: l10n.errGeneric,
          onRetry: () => ref.invalidate(examsByStudentProvider(studentId)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
                icon: Icons.event_note_outlined, title: l10n.noExamsForChild);
          }
          final Map<DateTime, List<Exam>> byWeek = {};
          for (final Exam exam in list) {
            byWeek.putIfAbsent(exam.weekStart, () => []).add(exam);
          }
          final List<DateTime> weeks = byWeek.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(examsByStudentProvider(studentId).future),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.screen,
                  DirasstySpace.sm, DirasstySpace.screen, DirasstySpace.xxl),
              children: [
                for (final DateTime week in weeks) ...[
                  Text(l10n.weekOf(DirasstyDates.dayMonthYear(week, lang)),
                      style: type.subheading),
                  const SizedBox(height: DirasstySpace.md),
                  DirasstyCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (int i, Exam e)
                            in byWeek[week]!.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _ExamRow(exam: e),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DirasstySpace.xl),
                ],
              ],
            ),
          );
        },
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
    final double? score = exam.scoreRatio;

    final Widget trailing = switch (exam.status) {
      ExamStatus.completed => Text(
          score == null
              ? '${exam.correctCount ?? 0}/${exam.totalQuestions}'
              : '${(score * 100).round()} %',
          textDirection: TextDirection.ltr,
          style: type.subheading.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            color: (score ?? 0) >= 0.75 ? DirasstyColors.teal : DirasstyColors.ink,
          ),
        ),
      ExamStatus.missed => DirasstyChip(
          label: l10n.missed, variant: DirasstyChipVariant.red, dense: true),
      _ => DirasstyChip(
          label: l10n.upcoming, variant: DirasstyChipVariant.gold, dense: true),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DirasstySpace.lg, vertical: DirasstySpace.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: DirasstyColors.track, shape: BoxShape.circle),
              child:
                  Text(exam.subject.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.subject.label, style: type.subheading),
                  const SizedBox(height: 2),
                  Text(l10n.questionsCount(exam.totalQuestions),
                      style: type.label.copyWith(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
