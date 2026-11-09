import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_promotion_config.dart';
import '../../../core/models/student.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/app_auth_state.dart';
import '../../auth/application/auth_providers.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../parent/application/parent_providers.dart';
import '../../parent/presentation/parent_shell_screen.dart';
import '../../student/application/student_providers.dart';
import '../application/apple_iap_providers.dart';
import '../data/apple_iap_service.dart';

/// iOS subscription screen: plans sold with Apple In-App Purchase as
/// non-renewing passes (App Store rules 3.1.1 / 3.1.2). Shows only Apple's
/// prices, what each pass gives and for how long, "Restaurer mes achats",
/// and the Terms / Privacy links. Never mentions any other way to pay —
/// not even a support button here (StorePolicy). A parent picks which
/// child the pass is for; a student buys for themselves.
class AppleSubscribeScreen extends ConsumerStatefulWidget {
  const AppleSubscribeScreen({
    super.key,
    this.preselectedStudentId,
    this.embedded = false,
  });

  final String? preselectedStudentId;

  /// Inside the parent's Abonnement tab: no back arrow.
  final bool embedded;

  @override
  ConsumerState<AppleSubscribeScreen> createState() =>
      _AppleSubscribeScreenState();
}

class _AppleSubscribeScreenState extends ConsumerState<AppleSubscribeScreen> {
  String? _studentId;
  String? _productId;

  /// Apple's standard licence agreement (used when an app has no own EULA).
  static const String _termsUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  @override
  void initState() {
    super.initState();
    _studentId = widget.preselectedStudentId;
    // A result left over from an earlier visit isn't shown again.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(applePurchaseControllerProvider.notifier).reset(),
    );
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  String _errorText(AppLocalizations l10n, String? code) => switch (code) {
        'network' ||
        'server_error' ||
        'not_signed_in' =>
          l10n.applePurchasePendingBody,
        'refunded' => l10n.applePurchaseRefunded,
        _ => l10n.applePurchaseFailed,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool isArabic = context.isArabicLocale;
    final bool selfMode =
        ref.watch(appAuthStateProvider).valueOrNull is AppAuthStudent;
    final AsyncValue<List<Student>> students = selfMode
        ? ref.watch(currentStudentProvider).whenData((s) => [s])
        : ref.watch(studentsByParentProvider);
    final AsyncValue<List<AppleOffer>> offers = ref.watch(appleOffersProvider);
    final ApplePurchaseState purchase =
        ref.watch(applePurchaseControllerProvider);

    void leave() {
      if (context.canPop()) {
        context.pop();
      } else if (selfMode) {
        context.goNamed(StudentHomeScreen.name);
      } else {
        context.go(ParentShellScreen.path);
      }
    }

    if (purchase.phase == ApplePurchasePhase.success) {
      return Scaffold(
        backgroundColor: DirasstyColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DirasstySpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconBadge(icon: Icons.check_rounded, size: 96),
                const SizedBox(height: DirasstySpace.xl),
                Text(
                  l10n.applePurchaseSuccessTitle,
                  textAlign: TextAlign.center,
                  style: type.title,
                ),
                const SizedBox(height: DirasstySpace.sm),
                Text(
                  l10n.applePurchaseSuccessBody,
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: DirasstyColors.textMuted),
                ),
                const SizedBox(height: DirasstySpace.xxl),
                DirasstyButton(
                  label: l10n.continueAction,
                  onPressed: () {
                    ref.read(applePurchaseControllerProvider.notifier).reset();
                    leave();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Student> kids = students.valueOrNull ?? const [];
    final String? studentId =
        _studentId ?? (kids.length == 1 ? kids.first.id : null);
    final List<AppleOffer> list = offers.valueOrNull ?? const [];
    final AppleOffer? selected =
        list.where((o) => o.product.id == _productId).firstOrNull ??
            (list.isEmpty ? null : list.first);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.embedded ? null : BackButton(onPressed: leave),
      ),
      body: SafeArea(
        top: false,
        child: students.isLoading || offers.isLoading
            ? const Center(child: CircularProgressIndicator())
            : students.hasError || offers.hasError
                ? ErrorState(
                    title: l10n.errGeneric,
                    onRetry: () {
                      ref.invalidate(appleOffersProvider);
                      ref.invalidate(studentsByParentProvider);
                      ref.invalidate(currentStudentProvider);
                    },
                  )
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DirasstySpace.screen,
                      DirasstySpace.sm,
                      DirasstySpace.screen,
                      DirasstySpace.xl,
                    ),
                    children: [
                      Text(l10n.appleSubscribeTitle, style: type.title),
                      const SizedBox(height: DirasstySpace.xs),
                      Text(
                        l10n.appleSubscribeBody,
                        style: type.body.copyWith(
                          color: DirasstyColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: DirasstySpace.xl),
                      if (!selfMode && kids.length > 1) ...[
                        Text(
                          l10n.appleSubscribeForChild,
                          style: type.subheading,
                        ),
                        const SizedBox(height: DirasstySpace.sm),
                        Wrap(
                          spacing: DirasstySpace.sm,
                          runSpacing: DirasstySpace.sm,
                          children: [
                            for (final Student s in kids)
                              ChoiceChip(
                                label: Text(s.name),
                                selected: studentId == s.id,
                                onSelected: (_) =>
                                    setState(() => _studentId = s.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: DirasstySpace.xl),
                      ],
                      if (list.isEmpty)
                        DirasstyCard(
                          child: Text(
                            l10n.appleSubscribeUnavailable,
                            style: type.body,
                          ),
                        )
                      else
                        for (final AppleOffer o in list) ...[
                          _OfferCard(
                            offer: o,
                            isArabic: isArabic,
                            selected: o.product.id == selected?.product.id,
                            onTap: purchase.busy
                                ? null
                                : () =>
                                    setState(() => _productId = o.product.id),
                          ),
                          const SizedBox(height: DirasstySpace.md),
                        ],
                      if (purchase.phase == ApplePurchasePhase.error) ...[
                        const SizedBox(height: DirasstySpace.sm),
                        Text(
                          _errorText(l10n, purchase.errorCode),
                          style: type.bodySmall.copyWith(
                            color: DirasstyColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: DirasstySpace.lg),
                      DirasstyButton(
                        label: purchase.phase == ApplePurchasePhase.verifying
                            ? l10n.applePurchaseVerifying
                            : l10n.appleSubscribeButton,
                        variant: DirasstyButtonVariant.gold,
                        loading: purchase.busy,
                        onPressed: selected == null ||
                                studentId == null ||
                                purchase.busy
                            ? null
                            : () => ref
                                .read(applePurchaseControllerProvider.notifier)
                                .buy(selected, studentId),
                      ),
                      if (!selfMode && kids.length > 1 && studentId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: DirasstySpace.sm),
                          child: Text(
                            l10n.appleSubscribePickChild,
                            textAlign: TextAlign.center,
                            style: type.bodySmall,
                          ),
                        ),
                      const SizedBox(height: DirasstySpace.sm),
                      DirasstyButton(
                        label: l10n.restorePurchases,
                        variant: DirasstyButtonVariant.quiet,
                        onPressed: purchase.busy
                            ? null
                            : () => ref
                                .read(applePurchaseControllerProvider.notifier)
                                .restore(),
                      ),
                      const SizedBox(height: DirasstySpace.xl),
                      Text(
                        l10n.appleSubscribeLegal,
                        style: type.label,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DirasstySpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _open(_termsUrl),
                            child: Text(l10n.termsOfUse),
                          ),
                          Text('·', style: type.label),
                          TextButton(
                            onPressed: () =>
                                _open(AppPromotionConfig.privacyPolicyUrl),
                            child: Text(l10n.privacyPolicy),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isArabic,
    required this.selected,
    required this.onTap,
  });

  final AppleOffer offer;
  final bool isArabic;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: DirasstyRadius.cardR,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(DirasstySpace.lg),
          decoration: BoxDecoration(
            color: selected ? DirasstyColors.tealTint : DirasstyColors.surface,
            borderRadius: DirasstyRadius.cardR,
            border: Border.all(
              color: selected ? DirasstyColors.teal : DirasstyColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? DirasstyColors.teal : DirasstyColors.idle,
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.plan.name(isArabic), style: type.subheading),
                    const SizedBox(height: DirasstySpace.xs),
                    Text(
                      l10n.applePassDuration(offer.plan.durationDays),
                      style: type.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Text(
                offer.product.price,
                style: type.heading.copyWith(color: DirasstyColors.teal),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
