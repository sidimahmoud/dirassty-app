import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/config/store_policy.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/plan.dart';
import '../../../core/models/student.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../courses/application/courses_providers.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../student/application/student_providers.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../subscription/presentation/subscribe_flow_screen.dart';
import 'widgets/auth_scaffold.dart';

/// Step 3 of student registration, right after the account is created
/// (the trial itself was already granted by
/// PostRegistrationTrialController).
///
/// The trial length and "à partir de [PRIX] MRU" price come from the
/// admin settings and active plans — never hardcoded (the design's
/// "7 jours" is just the current default). When the admin has trials
/// switched off, the same screen offers to pick a plan instead.
///
/// On iOS (StorePolicy) there is no price, no payment wording and no
/// plan picker: just the trial, or "account ready" with the free first
/// lessons.
///
/// design_handoff TrialOffer.dc.html · DESIGN_SPEC §4 "Trial offer".
class TrialOfferScreen extends ConsumerWidget {
  const TrialOfferScreen({super.key});

  static const String path = '/trial-offer';
  static const String name = 'trialOffer';

  /// Cheapest active plan expressed per 30 days (after its discount),
  /// rounded — the "à partir de" price. Null with no active plan.
  static int? cheapestMonthlyPrice(List<Plan> plans) {
    final Iterable<double> monthly = plans
        .where((p) => p.durationDays > 0)
        .map((p) => p.effectivePriceMru * 30 / p.durationDays);
    if (monthly.isEmpty) return null;
    return monthly.reduce((a, b) => a < b ? a : b).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<AppSettings> settings = ref.watch(appSettingsProvider);
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;
    final int? price =
        ref.watch(activePlansProvider).whenOrNull(data: cheapestMonthlyPrice);
    final String gradeLabel =
        student == null ? '' : gradeName(ref, student.grade);

    void goHome() {
      ref
          .read(appAnalyticsProvider)
          .track('onboarding_completed', {'role': 'student'});
      context.go(StudentHomeScreen.path);
    }

    return settings.when(
      loading: () => const Scaffold(
        backgroundColor: DirasstyColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      // Settings unreachable — don't block a freshly created account.
      error: (_, __) => _AccountReady(gradeLabel: gradeLabel, onLater: goHome),
      data: (s) => !s.trialEnabled
          ? _AccountReady(gradeLabel: gradeLabel, onLater: goHome)
          : AuthScaffold(
              showBack: false,
              sidePadding: DirasstySpace.xl,
              gap: DirasstySpace.xl,
              bottom: [
                DirasstyButton(label: l10n.startTrial, onPressed: goHome),
                if (StorePolicy.inAppSalesAllowed)
                  Text(
                    price == null
                        ? l10n.trialFooterNoPrice
                        : l10n.trialFooterPrice('$price'),
                    textAlign: TextAlign.center,
                    style: type.label.copyWith(fontWeight: FontWeight.w400),
                  ),
              ],
              children: [
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(top: DirasstySpace.xl),
                  child: Column(
                    children: [
                      const IconBadge(
                        icon: Icons.card_giftcard_rounded,
                        size: 112,
                        background: DirasstyColors.goldTint,
                        foreground: DirasstyColors.goldStroke,
                      ),
                      const SizedBox(height: DirasstySpace.screen),
                      DirasstyChip(
                        label: l10n.accountCreated,
                        variant: DirasstyChipVariant.teal,
                        dense: true,
                      ),
                      const SizedBox(height: DirasstySpace.screen),
                      Text(
                        l10n.trialTitleDays(s.trialDurationDays),
                        textAlign: TextAlign.center,
                        style: type.display,
                      ),
                      const SizedBox(height: DirasstySpace.sm),
                      Text(
                        gradeLabel.isEmpty
                            ? l10n.trialBody
                            : l10n.trialBodyGrade(gradeLabel),
                        textAlign: TextAlign.center,
                        style:
                            type.body.copyWith(color: DirasstyColors.textMuted),
                      ),
                    ],
                  ),
                ),
                DirasstyCard(
                  variant: DirasstyCardVariant.shadow,
                  padding:
                      const EdgeInsetsDirectional.all(DirasstySpace.screen),
                  child: Column(
                    children: [
                      for (final (int i, String feature) in [
                        l10n.trialFeatureLessons,
                        l10n.trialFeatureQcm,
                        l10n.trialFeatureExams,
                        l10n.trialFeatureHelper,
                      ].indexed) ...[
                        if (i > 0) const SizedBox(height: DirasstySpace.md),
                        Row(
                          children: [
                            const IconBadge(
                              icon: Icons.check_rounded,
                              size: 24,
                            ),
                            const SizedBox(width: DirasstySpace.md),
                            Expanded(child: Text(feature, style: type.body)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Trials switched off by the admin: the account is ready, pick a plan —
/// on iOS just start, with the free first lessons (StorePolicy).
class _AccountReady extends StatelessWidget {
  const _AccountReady({required this.gradeLabel, required this.onLater});

  final String gradeLabel;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool canSell = StorePolicy.inAppSalesAllowed;
    return AuthScaffold(
      onBack: onLater,
      sidePadding: DirasstySpace.xl,
      bottom: [
        if (canSell) ...[
          DirasstyButton(
            label: l10n.choosePlan,
            variant: DirasstyButtonVariant.gold,
            onPressed: () => context.go(SubscribeFlowScreen.path),
          ),
          DirasstyButton(
            label: l10n.later,
            variant: DirasstyButtonVariant.quiet,
            onPressed: onLater,
          ),
        ] else
          DirasstyButton(label: l10n.getStarted, onPressed: onLater),
      ],
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: DirasstySpace.xxl),
          child: Column(
            children: [
              const IconBadge(icon: Icons.check_rounded, size: 112),
              const SizedBox(height: DirasstySpace.screen),
              Text(
                l10n.accountReadyTitle,
                textAlign: TextAlign.center,
                style: type.display,
              ),
              const SizedBox(height: DirasstySpace.sm),
              Text(
                canSell
                    ? l10n.accountReadyBody(gradeLabel)
                    : l10n.accountReadyFreeLessonsBody,
                textAlign: TextAlign.center,
                style: type.body.copyWith(color: DirasstyColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
