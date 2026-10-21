import '../../../core/models/subscription.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';

/// The single place that turns a [Subscription] row into a status chip —
/// the parent home cards and "Mes abonnements" both read this, so the
/// same row can never be described two different ways.
({String label, DirasstyChipVariant variant}) subscriptionBadge(
  AppLocalizations l10n,
  Subscription sub,
) {
  final bool access = sub.grantsAccess;
  return switch (sub.status) {
    SubscriptionStatus.trial when access => (
        label: l10n.trialDaysLeft(sub.daysLeftInTrial),
        variant: DirasstyChipVariant.gold,
      ),
    SubscriptionStatus.trial => (
        label: l10n.statusTrialEnded,
        variant: DirasstyChipVariant.red,
      ),
    SubscriptionStatus.active when access => (
        label: l10n.statusActive,
        variant: DirasstyChipVariant.teal,
      ),
    SubscriptionStatus.active => (
        label: l10n.statusExpired,
        variant: DirasstyChipVariant.red,
      ),
    SubscriptionStatus.pending => (
        label: l10n.statusPending,
        variant: DirasstyChipVariant.gold,
      ),
    SubscriptionStatus.unpaid => (
        label: l10n.statusUnpaid,
        variant: DirasstyChipVariant.gold,
      ),
    SubscriptionStatus.scheduled => (
        label: l10n.statusScheduled,
        variant: DirasstyChipVariant.teal,
      ),
    SubscriptionStatus.paused => (
        label: l10n.statusPaused,
        variant: DirasstyChipVariant.neutral,
      ),
    // An admin rejecting a Bankily payment cancels the row.
    SubscriptionStatus.cancelled => (
        label: sub.paymentMethod == SubscriptionPaymentMethod.bankily
            ? l10n.statusRefused
            : l10n.statusCancelled,
        variant: DirasstyChipVariant.red,
      ),
  };
}
