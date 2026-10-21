import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/grade.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/student_stats.dart';
import '../../../../core/models/subscription.dart';
import '../../../../core/text/study_time.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../courses/application/courses_providers.dart';
import '../../../progress/application/progress_providers.dart';
import '../../../subscription/presentation/subscribe_flow_screen.dart';

/// "4ème Collège · Collège · Niveau 7" (the admin-saved class name).
String childGradeLine(AppLocalizations l10n, WidgetRef ref, Student student) {
  final String cycle = switch (gradeCycle(student.grade)) {
    GradeCycle.primaire => l10n.cyclePrimary,
    GradeCycle.college => l10n.cycleMiddle,
    GradeCycle.lycee => l10n.cycleHigh,
  };
  return '${gradeName(ref, student.grade)} · $cycle · ${l10n.level(student.level)}';
}

/// Initial-letter avatar: teal when the child has access, neutral
/// otherwise (ParentHome.dc.html).
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    required this.name,
    this.active = true,
    this.size = 48,
    super.key,
  });

  final String name;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? DirasstyColors.tealTint : DirasstyColors.neutralAvatar,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: context.dirasstyType.subheading.copyWith(
          fontSize: size * 0.375,
          fontWeight: FontWeight.w800,
          color: active ? DirasstyColors.teal : DirasstyColors.ink,
        ),
      ),
    );
  }
}

/// One child on the parent home: avatar, grade · cycle · level, a
/// subscription status chip, streak + time studied this week, a 7-day
/// activity chart, and — for a trial / lapsed child — a gold "S'abonner
/// pour {prénom}" button.
///
/// design_handoff ParentHome.dc.html · DESIGN_SPEC §4 "Parent space".
class ChildCard extends ConsumerWidget {
  const ChildCard({
    required this.student,
    required this.subscription,
    required this.onTap,
    super.key,
  });

  final Student student;
  final Subscription? subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final StudentStats? stats =
        ref.watch(studentStatsProvider(student.id)).valueOrNull;
    final Subscription? sub = subscription;
    final bool paidActive = sub != null &&
        sub.status == SubscriptionStatus.active &&
        sub.grantsAccess;
    final bool pending = sub?.status == SubscriptionStatus.pending;
    final bool showSubscribe = !paidActive && !pending;

    final DirasstyChip? chip = switch (sub) {
      null => null,
      _ when paidActive => DirasstyChip(
          label: l10n.statusActive,
          variant: DirasstyChipVariant.teal,
        ),
      _ when pending => DirasstyChip(
          label: l10n.statusPending,
          variant: DirasstyChipVariant.gold,
        ),
      _ when sub.status == SubscriptionStatus.trial && sub.grantsAccess =>
        DirasstyChip(
          label: l10n.trialDaysLeft(sub.daysLeftInTrial),
          variant: DirasstyChipVariant.gold,
        ),
      _ when sub.isUpcoming => null,
      _ => DirasstyChip(
          label: l10n.statusExpired,
          variant: DirasstyChipVariant.red,
        ),
    };

    return DirasstyCard(
      variant: DirasstyCardVariant.shadow,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChildAvatar(name: student.name, active: paidActive),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.subheading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      childGradeLine(l10n, ref, student),
                      style: type.label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (chip != null) chip,
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (student.streak > 0) ...[
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: DirasstyColors.goldStroke,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: student.streak > 0
                            ? l10n.streakDaysShort(student.streak)
                            : l10n.noStreak,
                        style: type.subheading.copyWith(fontSize: 14),
                      ),
                      if (stats != null)
                        TextSpan(
                          text:
                              ' ${l10n.timeThisWeek(formatStudyTime(l10n, stats.week.minutesOnApp))}',
                          style:
                              type.label.copyWith(fontWeight: FontWeight.w400),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              const Spacer(),
              _ActivityBars(
                minutes: stats?.last7DaysMinutes ?? const [],
                color: paidActive ? DirasstyColors.teal : DirasstyColors.ink,
                label: l10n.activityLast7Days,
              ),
            ],
          ),
          if (showSubscribe) ...[
            const SizedBox(height: 14),
            DirasstyButton(
              label: l10n.subscribeFor(student.name),
              variant: DirasstyButtonVariant.gold,
              compact: true,
              onPressed: () =>
                  context.push(SubscribeFlowScreen.path, extra: student.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Seven 6 px bars, oldest → today, scaled to the busiest day (4 px
/// floor for idle days). Always LTR so "today" stays on the right, like
/// a timeline, in Arabic too.
class _ActivityBars extends StatelessWidget {
  const _ActivityBars({
    required this.minutes,
    required this.color,
    required this.label,
  });

  final List<int> minutes;
  final Color color;
  final String label;

  static const double _maxHeight = 32;

  @override
  Widget build(BuildContext context) {
    final List<int> days =
        minutes.length == 7 ? minutes : List<int>.filled(7, 0);
    final int busiest = days.fold(0, (a, b) => a > b ? a : b);
    return Semantics(
      label: label,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: _maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (int i, int m) in days.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: m == 0 || busiest == 0
                      ? 4
                      : 4 + (m / busiest) * (_maxHeight - 6),
                  decoration: BoxDecoration(
                    color: m == 0 ? DirasstyColors.inactiveBar : color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
