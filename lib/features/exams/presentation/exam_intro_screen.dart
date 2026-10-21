import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/gamification/gamification.dart';
import '../../../core/models/exam.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'exam_session_screen.dart';

/// Before a weekly exam: subject, duration (or due date while exams have
/// no stored time limit), question count, max XP, the rules, "Commencer".
///
/// "XP max" is the true upper bound: every question right at the hardest
/// difficulty, plus the completion bonus.
///
/// design_handoff ExamIntro.dc.html · DESIGN_SPEC §4 "Exams › Intro".
class ExamIntroScreen extends StatelessWidget {
  const ExamIntroScreen({required this.exam, super.key});

  static const String path = '/exam/:examId/intro';
  static const String name = 'examIntro';

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final int xpMax = exam.totalQuestions * XpRewards.correctHard +
        XpRewards.examCompletionBonus;
    final List<String> rules = [
      l10n.examRuleTimer,
      l10n.examRuleSkip,
      l10n.examRuleCalm,
      l10n.examRuleSaved,
    ];

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen,
          0,
          DirasstySpace.screen,
          DirasstySpace.xxl,
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DirasstyChip(
              label: l10n.weeklyExamBadge,
              variant: DirasstyChipVariant.gold,
              dense: true,
            ),
          ),
          const SizedBox(height: DirasstySpace.lg),
          Text(exam.subject.label, style: type.display),
          const SizedBox(height: DirasstySpace.screen),
          Row(
            children: [
              if (exam.durationMinutes != null)
                _Tile(
                  value: l10n.minutesShort(exam.durationMinutes!),
                  label: l10n.duration,
                )
              else
                _Tile(
                  value: DirasstyDates.dayMonthYear(exam.dueAt, lang),
                  label: l10n.dueBy,
                  small: true,
                ),
              const SizedBox(width: 10),
              _Tile(
                value: '${exam.totalQuestions}',
                label: l10n.questionsLabel,
              ),
              const SizedBox(width: 10),
              _Tile(value: '+$xpMax', label: l10n.xpMax),
            ],
          ),
          const SizedBox(height: DirasstySpace.screen),
          DirasstyCard(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.beforeStart, style: type.subheading),
                for (final String rule in rules) ...[
                  const SizedBox(height: DirasstySpace.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(top: 8),
                        decoration: const BoxDecoration(
                          color: DirasstyColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule,
                          style: type.bodySmall
                              .copyWith(color: DirasstyColors.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DirasstySpace.xl),
          DirasstyButton(
            label: l10n.startExam,
            onPressed: () =>
                context.pushReplacement(ExamSessionScreen.pathFor(exam.id)),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, this.small = false});

  final String value;
  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Expanded(
      child: DirasstyCard(
        padding: const EdgeInsetsDirectional.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.titleSmall.copyWith(fontSize: small ? 15 : 20),
            ),
            const SizedBox(height: 2),
            Text(label, style: type.label),
          ],
        ),
      ),
    );
  }
}
