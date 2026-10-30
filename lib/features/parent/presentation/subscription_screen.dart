import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/config/store_policy.dart';
import '../../../core/models/student.dart';
import '../../../core/models/subscription.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../subscription/presentation/subscribe_flow_screen.dart';
import '../../subscription/presentation/subscription_labels.dart';
import '../application/parent_providers.dart';
import 'widgets/child_card.dart';

/// "Mes abonnements": one card per child with its current state —
/// Actif (end date), En vérification (payment details + support), Expiré
/// (Renouveler), Refusé (Réessayer) — plus any queued renewal, then the
/// history of past rows. Subscriptions are per child (see
/// 016_student_subscriptions.sql). Opened from the Abonnement tab's
/// "Voir mes abonnements".
///
/// On iOS (StorePolicy) this is the whole Subscription tab and shows
/// status only: no subscribe / renew / retry buttons.
///
/// Deviation from SubscriptionStatus.dc.html: a refused payment shows no
/// reason — rows don't carry one yet (TODO(api)).
///
/// design_handoff SubscriptionStatus.dc.html · DESIGN_SPEC §4 "Status".
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const String path = '/parent/subscriptions';
  static const String name = 'parentSubscriptions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<List<Student>> students =
        ref.watch(studentsByParentProvider);
    final AsyncValue<List<Subscription>> all =
        ref.watch(subscriptionsByParentProvider);
    final Map<String, Subscription> current =
        ref.watch(latestSubscriptionsByStudentProvider).valueOrNull ?? const {};
    final Map<String, Subscription> upcoming =
        ref.watch(upcomingSubscriptionsByStudentProvider).valueOrNull ??
            const {};

    Future<void> refresh() async {
      ref.invalidate(studentsByParentProvider);
      ref.invalidate(subscriptionsByParentProvider);
      await ref.read(subscriptionsByParentProvider.future);
    }

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(l10n.subscription)),
      body: (students.isLoading || all.isLoading)
          ? const _Skeleton()
          : (students.hasError || all.hasError)
              ? ErrorState(title: l10n.errGeneric, onRetry: refresh)
              : RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DirasstySpace.screen,
                      0,
                      DirasstySpace.screen,
                      DirasstySpace.xxl,
                    ),
                    children: [
                      Text(l10n.mySubscriptions, style: type.title),
                      const SizedBox(height: DirasstySpace.xl),
                      for (final Student s in students.value!) ...[
                        _ChildStatusCard(
                          student: s,
                          subscription: current[s.id],
                          upcoming: upcoming[s.id],
                        ),
                        const SizedBox(height: DirasstySpace.md),
                      ],
                      const SizedBox(height: DirasstySpace.lg),
                      Text(l10n.history, style: type.subheading),
                      const SizedBox(height: DirasstySpace.md),
                      _History(
                        students: students.value!,
                        rows: all.value!
                            .where(
                              (r) =>
                                  !current.values.any((c) => c.id == r.id) &&
                                  !r.isUpcoming,
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ChildStatusCard extends StatelessWidget {
  const _ChildStatusCard({
    required this.student,
    required this.subscription,
    required this.upcoming,
  });

  final Student student;
  final Subscription? subscription;
  final Subscription? upcoming;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = context.isArabicLocale;
    final Subscription? sub = subscription;
    final ({String label, DirasstyChipVariant variant})? badge =
        sub == null ? null : subscriptionBadge(l10n, sub);

    String date(DateTime d) => DirasstyDates.dayMonthYear(d, lang);
    String dateTime(DateTime d) {
      final DateTime l = d.toLocal();
      return '${date(l)} · ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    final bool canSell = StorePolicy.inAppSalesAllowed;
    void subscribe() =>
        context.push(SubscribeFlowScreen.path, extra: student.id);

    final String? detail;
    final Widget? action;
    if (sub == null) {
      detail = canSell ? l10n.noSubscriptionBody : l10n.childNotActiveBody;
      action = !canSell
          ? null
          : DirasstyButton(
              label: l10n.subscribeAction,
              variant: DirasstyButtonVariant.gold,
              compact: true,
              onPressed: subscribe,
            );
    } else if (sub.grantsAccess) {
      detail = sub.expiresAt == null
          ? null
          : (sub.status == SubscriptionStatus.trial
              ? l10n.trialUntil(date(sub.expiresAt!))
              : l10n.accessUntil(date(sub.expiresAt!)));
      action =
          canSell && sub.status == SubscriptionStatus.trial && upcoming == null
              ? DirasstyButton(
                  label: l10n.subscribeFor(student.name),
                  variant: DirasstyButtonVariant.gold,
                  compact: true,
                  onPressed: subscribe,
                )
              : null;
    } else if (sub.status == SubscriptionStatus.pending) {
      detail =
          l10n.pendingDetails(dateTime(sub.createdAt), sub.paymentCode ?? '—');
      action = DirasstyButton(
        label: l10n.contactSupport,
        icon: Icons.chat_outlined,
        variant: DirasstyButtonVariant.secondary,
        compact: true,
        onPressed: () => contactSupport(context),
      );
    } else if (sub.status == SubscriptionStatus.unpaid) {
      detail = l10n.unpaidDetails;
      action = DirasstyButton(
        label: l10n.contactSupport,
        icon: Icons.chat_outlined,
        variant: DirasstyButtonVariant.secondary,
        compact: true,
        onPressed: () => contactSupport(context),
      );
    } else if (sub.isUpcoming) {
      detail = null;
      action = null;
    } else {
      final bool refused = sub.status == SubscriptionStatus.cancelled &&
          sub.paymentMethod == SubscriptionPaymentMethod.bankily;
      detail =
          sub.expiresAt == null ? null : l10n.endedOn(date(sub.expiresAt!));
      action = upcoming != null || !canSell
          ? null
          : DirasstyButton(
              label: refused ? l10n.retry : l10n.renew,
              compact: true,
              onPressed: subscribe,
            );
    }

    final Subscription? next = upcoming;
    return DirasstyCard(
      variant: DirasstyCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChildAvatar(
                name: student.name,
                active: sub?.grantsAccess ?? false,
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: type.subheading.copyWith(fontSize: 16),
                    ),
                    Text(
                      sub == null
                          ? l10n.noSubscription
                          : (sub.plan?.name(isArabic) ?? l10n.freeTrial),
                      style: type.label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                DirasstyChip(label: badge.label, variant: badge.variant),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: DirasstySpace.md),
            Text(detail, style: type.bodySmall),
          ],
          if (next != null &&
              next.currentPeriodStart != null &&
              next.currentPeriodEnd != null) ...[
            const SizedBox(height: DirasstySpace.md),
            Container(
              padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
              decoration: const BoxDecoration(
                color: DirasstyColors.tealTint,
                borderRadius: DirasstyRadius.smallR,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: DirasstyColors.teal,
                  ),
                  const SizedBox(width: DirasstySpace.sm),
                  Expanded(
                    child: Text(
                      l10n.upcomingPlan(
                        next.plan?.name(isArabic) ?? '',
                        date(next.currentPeriodStart!),
                        date(next.currentPeriodEnd!),
                      ),
                      style:
                          type.label.copyWith(color: DirasstyColors.tealDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: DirasstySpace.lg),
            action,
          ],
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.students, required this.rows});

  final List<Student> students;
  final List<Subscription> rows;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = context.isArabicLocale;
    if (rows.isEmpty) {
      return Text(
        l10n.noHistory,
        style: type.bodySmall.copyWith(color: DirasstyColors.textMuted),
      );
    }
    final Map<String, String> names = {
      for (final Student s in students) s.id: s.name,
    };
    return DirasstyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (int i, Subscription r) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: DirasstySpace.lg,
                vertical: DirasstySpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${names[r.studentId] ?? ''} · ${r.plan?.name(isArabic) ?? l10n.freeTrial}',
                          style: type.subheading.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.startsAt != null && r.expiresAt != null
                              ? '${DirasstyDates.dayMonthYear(r.startsAt!, lang)} → ${DirasstyDates.dayMonthYear(r.expiresAt!, lang)}'
                              : DirasstyDates.dayMonthYear(r.createdAt, lang),
                          style:
                              type.label.copyWith(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final badge = subscriptionBadge(l10n, r);
                      return DirasstyChip(
                        label: badge.label,
                        variant: badge.variant,
                        dense: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
        Skeleton(height: 28, width: 200),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 140, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 140, radius: DirasstyRadius.card),
      ],
    );
  }
}
