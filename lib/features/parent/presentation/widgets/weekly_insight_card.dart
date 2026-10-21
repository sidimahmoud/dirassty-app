import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/weekly_insight.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_report/presentation/report_ai_button.dart';
import '../../application/parent_providers.dart';

/// "Analyse de la semaine": the AI-written summary (2–3 sentences, built
/// only from the child's real data server-side) plus a suggested action.
/// Generated on first view each week, cached after that (see
/// WeeklyInsightRepository) — so only the very first view can be slow.
///
/// design_handoff ChildProgress.dc.html · DESIGN_SPEC §4 "Child progress".
class WeeklyInsightCard extends ConsumerWidget {
  const WeeklyInsightCard({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<WeeklyInsight> insight =
        ref.watch(weeklyInsightProvider(studentId));

    final Widget body = insight.when(
      loading: () => Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DirasstyColors.teal,
            ),
          ),
          const SizedBox(width: DirasstySpace.sm),
          Expanded(child: Text(l10n.insightLoading, style: type.bodySmall)),
        ],
      ),
      error: (_, __) => Text(l10n.insightUnavailable, style: type.bodySmall),
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            value.insightText,
            style: type.body.copyWith(fontSize: 14, height: 1.55),
          ),
          if (value.suggestionText.trim().isNotEmpty) ...[
            const SizedBox(height: DirasstySpace.md),
            Container(
              padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
              decoration: const BoxDecoration(
                color: DirasstyColors.goldTint,
                borderRadius: DirasstyRadius.smallR,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: DirasstyColors.goldStroke,
                  ),
                  const SizedBox(width: DirasstySpace.sm),
                  Expanded(
                    child: Text(
                      value.suggestionText,
                      style:
                          type.bodySmall.copyWith(color: DirasstyColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DirasstySpace.sm),
          Text(
            l10n.insightGenerated,
            style: type.label.copyWith(fontWeight: FontWeight.w400),
          ),
          ReportAiButton(
            feature: 'insight',
            aiText: '${value.insightText}\n${value.suggestionText}',
            studentId: studentId,
          ),
        ],
      ),
    );

    return DirasstyCard(
      variant: DirasstyCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: DirasstyColors.teal,
              ),
              const SizedBox(width: DirasstySpace.sm),
              Text(
                l10n.weeklyInsight,
                style: type.subheading.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.md),
          body,
        ],
      ),
    );
  }
}
