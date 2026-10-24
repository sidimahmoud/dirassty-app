import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/payment_method.dart';
import '../../../core/models/plan.dart';
import '../../../core/models/student.dart';
import '../../../core/models/subscription.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/app_auth_state.dart';
import '../../auth/application/auth_providers.dart';
import '../../courses/application/courses_providers.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../marketing/presentation/promo_code_field.dart';
import '../../parent/application/parent_providers.dart';
import '../../parent/presentation/parent_shell_screen.dart';
import '../../parent/presentation/subscription_screen.dart';
import '../../parent/presentation/widgets/child_card.dart';
import '../../student/application/student_providers.dart';
import '../application/subscription_providers.dart';

enum _Step { select, bankily, success }

enum _SuccessKind { bankily, contact }

/// One flow for subscribing and renewing — a parent for one or more
/// children, or a student for themselves (038_students_self_manage_
/// subscription.sql); server-side all are identical: one pending/unpaid
/// row per target student, activated by an admin.
///
/// 1. Plans (radio cards) + "Pour quels enfants ?" (parents only) + the
///    summary and total → one button per payment method (Admin →
///    Paramètres → Moyens de paiement: name, logo, number), or "Payer
///    manuellement" (the team finalises the payment with the customer on
///    WhatsApp; the rows go to **unpaid**, visible to admins as manual
///    requests).
/// 2. The chosen method: amount, its number, 3 steps, payer's phone + a
///    screenshot of the confirmation (uploaded to the private
///    `payment-proofs` bucket) → the rows go to **pending** and the admin
///    checks the screenshot in Abonnements.
/// 3. Confirmation.
///
/// Also the parent's Abonnement tab ([embedded]: no back arrow, and
/// "Terminé" returns to step 1 instead of leaving).
///
/// Family discount (045/046 migrations): subscribing several children
/// together lowers the price of every child after the first
/// automatically (the first keeps the plan price); all
/// eligible children start selected and a nudge shows what adding one
/// more would save. The real charge is computed server-side by
/// `request_subscriptions()`; [AppSettings.quote] only mirrors it for
/// display.
///
/// Payment methods come from [paymentMethodsProvider] (one request, only
/// when this screen opens); no verification delay is promised.
///
/// design_handoff Subscription.dc.html, BankilyPayment.dc.html ·
/// DESIGN_SPEC §4 "Subscription" / "Bankily payment".
class SubscribeFlowScreen extends ConsumerStatefulWidget {
  const SubscribeFlowScreen({
    super.key,
    this.preselectedStudentId,
    this.embedded = false,
  });

  static const String path = '/parent/subscribe';
  static const String name = 'subscribeFlow';

  final String? preselectedStudentId;
  final bool embedded;

  @override
  ConsumerState<SubscribeFlowScreen> createState() =>
      _SubscribeFlowScreenState();
}

class _SubscribeFlowScreenState extends ConsumerState<SubscribeFlowScreen> {
  _Step _step = _Step.select;
  Plan? _plan;

  /// The method chosen on step 1 (null before).
  PaymentMethod? _method;
  final Set<String> _selectedStudentIds = {};

  /// Every eligible child is pre-selected once (unless the parent came
  /// from one child's "S'abonner pour …"), so the family price shows
  /// without the parent having to look for it.
  bool _defaultSelectionDone = false;
  _SuccessKind? _successKind;
  String? _selectError;

  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;

  /// The payer's screenshot of the Bankily confirmation (JPEG, resized).
  Uint8List? _proof;
  String? _proofError;

  /// Payment funnel events (docs/marketing-events.md). Kept as a field so
  /// [dispose] can still record an abandoned flow.
  late final AppAnalytics _analytics;
  bool _methodChosen = false;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStudentId != null) {
      _selectedStudentIds.add(widget.preselectedStudentId!);
    }
    _analytics = ref.read(appAnalyticsProvider);
    _analytics.track('plan_viewed', {
      'source_screen': widget.embedded ? 'subscription_tab' : 'subscribe_flow',
      'preselected_child': widget.preselectedStudentId != null,
    });
  }

  @override
  void dispose() {
    // Chose a way to pay, then left without sending the request.
    if (_methodChosen && !_requestSent) {
      _analytics.track('payment_cancelled', {'step': _step.name});
    }
    _phoneController.dispose();
    super.dispose();
  }

  void _trackMethod(String method, Plan plan, int children) {
    _methodChosen = true;
    _analytics.track('payment_method_selected', {
      'method': method,
      'plan_id': plan.id,
      'children': children,
    });
  }

  Plan? _effectivePlan(List<Plan> plans) {
    if (plans.isEmpty) return null;
    if (_plan != null && plans.any((p) => p.id == _plan!.id)) return _plan;
    return plans.where((p) => p.key == 'quarterly').firstOrNull ?? plans.first;
  }

  void _reset() => setState(() {
        _step = _Step.select;
        _successKind = null;
        _methodChosen = false;
        _requestSent = false;
        _phoneController.clear();
        _proof = null;
        _proofError = null;
      });

  Future<void> _pickProof() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 75,
    );
    if (picked == null) return;
    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proof = bytes;
      _proofError = null;
    });
  }

  Future<void> _submitTransfer(List<String> targets) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _phoneError =
          isValidPhone(_phoneController.text) ? null : l10n.errPhoneInvalid;
      _proofError = _proof == null ? l10n.errPaymentProofRequired : null;
    });
    if (_phoneError != null || _proofError != null) return;
    await ref.read(subscribeControllerProvider.notifier).submitTransfer(
          studentIds: targets,
          planId: _plan!.id,
          method: _method!,
          phone: _phoneController.text.trim(),
          proofJpeg: _proof!,
        );
    if (!mounted) return;
    if (ref.read(subscribeControllerProvider).hasError) {
      _analytics.track('payment_error', {'method': _method!.kind});
      return;
    }
    _requestSent = true;
    setState(() {
      _successKind = _SuccessKind.bankily;
      _step = _Step.success;
    });
  }

  Future<void> _submitContact(List<Student> targets) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDirasstyDialog<bool>(
      context,
      icon: Icons.chat_rounded,
      title: l10n.contactConfirmTitle,
      message: l10n.contactConfirmBody,
      actions: [
        DirasstyDialogAction(label: l10n.continueAction, value: true),
        DirasstyDialogAction(
          label: l10n.cancel,
          value: false,
          variant: DirasstyButtonVariant.quiet,
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    final Plan plan = _plan!;
    await ref.read(subscribeControllerProvider.notifier).submitContact(
      studentIds: [for (final s in targets) s.id],
      planId: plan.id,
    );
    if (!mounted) return;
    if (ref.read(subscribeControllerProvider).hasError) {
      _analytics.track('payment_error', {'method': 'contact'});
      return;
    }
    _requestSent = true;

    final bool isArabic = context.isArabicLocale;
    final String supportNumber = await supportWhatsappNumber(context);
    if (!mounted) return;
    final Uri uri = Uri.https('wa.me', '/$supportNumber', {
      'text': l10n.contactWhatsappMessage(
        plan.name(isArabic),
        _quote(plan, targets.length).totalMru.toStringAsFixed(0),
        targets.map((s) => s.name).join(isArabic ? '، ' : ', '),
      ),
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _successKind = _SuccessKind.contact;
      _step = _Step.success;
    });
  }

  FamilyQuote _quote(Plan plan, int children) {
    final AppSettings settings = ref.read(appSettingsProvider).valueOrNull ??
        const AppSettings(trialEnabled: false, trialDurationDays: 0);
    return settings.quote(plan, children);
  }

  /// A child already covered (paid and running, or a payment in review)
  /// isn't pre-selected.
  static bool _isCovered(Subscription? sub) =>
      sub != null &&
      ((sub.status == SubscriptionStatus.active && sub.grantsAccess) ||
          sub.status == SubscriptionStatus.pending ||
          sub.isUpcoming);

  void _applyDefaultSelection(List<Student> students) {
    if (_defaultSelectionDone || widget.preselectedStudentId != null) return;
    final Map<String, Subscription>? subs =
        ref.read(latestSubscriptionsByStudentProvider).valueOrNull;
    if (subs == null) return;
    _defaultSelectionDone = true;
    _selectedStudentIds.addAll(
      students.where((s) => !_isCovered(subs[s.id])).map((s) => s.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppAuthState> auth = ref.watch(appAuthStateProvider);
    final bool selfMode = auth.valueOrNull is AppAuthStudent;
    final AsyncValue<List<Student>> students = selfMode
        ? ref.watch(currentStudentProvider).whenData((s) => [s])
        : ref.watch(studentsByParentProvider);
    final AsyncValue<List<Plan>> plans = ref.watch(activePlansProvider);
    ref.watch(appSettingsProvider);
    if (!selfMode) {
      ref.watch(latestSubscriptionsByStudentProvider);
      final List<Student>? list = students.valueOrNull;
      if (list != null) _applyDefaultSelection(list);
    }

    final bool showBack =
        !(widget.embedded && _step == _Step.select) && _step != _Step.success;

    return PopScope(
      canPop: _step != _Step.bankily,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == _Step.bankily) {
          setState(() => _step = _Step.select);
        }
      },
      child: Scaffold(
        backgroundColor: DirasstyColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // Opened with context.go (offer screen) it can be the only
          // screen: then "back" goes home instead of doing nothing.
          leading: showBack
              ? BackButton(
                  onPressed: () {
                    if (_step == _Step.bankily) {
                      setState(() => _step = _Step.select);
                    } else if (context.canPop()) {
                      context.pop();
                    } else if (selfMode) {
                      context.goNamed(StudentHomeScreen.name);
                    } else {
                      context.go(ParentShellScreen.path);
                    }
                  },
                )
              : null,
          title: _step == _Step.bankily ? Text(l10n.subscription) : null,
        ),
        body: SafeArea(
          top: false,
          child: auth.isLoading || students.isLoading || plans.isLoading
              ? const _SelectSkeleton()
              : (students.hasError || plans.hasError)
                  ? ErrorState(
                      title: l10n.errGeneric,
                      onRetry: () {
                        ref.invalidate(activePlansProvider);
                        ref.invalidate(studentsByParentProvider);
                        ref.invalidate(currentStudentProvider);
                      },
                    )
                  : _buildStep(l10n, students.value!, plans.value!, selfMode),
        ),
      ),
    );
  }

  Widget _buildStep(
    AppLocalizations l10n,
    List<Student> allStudents,
    List<Plan> plans,
    bool selfMode,
  ) {
    final Plan? plan = _effectivePlan(plans);
    final List<Student> targets = selfMode
        ? allStudents
        : allStudents.where((s) => _selectedStudentIds.contains(s.id)).toList();
    final bool submitting = ref.watch(subscribeControllerProvider).isLoading;
    final String? serverError = ref.watch(subscribeControllerProvider).hasError
        ? l10n.errGeneric
        : null;

    return switch (_step) {
      _Step.select => _SelectStep(
          plans: plans,
          plan: plan,
          quoteFor: _quote,
          eligibleUnselected: selfMode
              ? const []
              : allStudents
                  .where(
                    (s) =>
                        !_selectedStudentIds.contains(s.id) &&
                        !_isCovered(
                          ref
                              .read(latestSubscriptionsByStudentProvider)
                              .valueOrNull?[s.id],
                        ),
                  )
                  .toList(),
          students: allStudents,
          selfMode: selfMode,
          selectedIds: _selectedStudentIds,
          targets: targets,
          embedded: widget.embedded,
          submitting: submitting,
          errorText: _selectError ?? serverError,
          onPlan: (p) => setState(() => _plan = p),
          onToggle: (id) => setState(() {
            _selectError = null;
            if (!_selectedStudentIds.remove(id)) _selectedStudentIds.add(id);
          }),
          methods: ref.watch(paymentMethodsProvider),
          onRetryMethods: () => ref.invalidate(paymentMethodsProvider),
          onMethod: (method) {
            if (plan == null) return;
            if (targets.isEmpty) {
              setState(() => _selectError = l10n.selectAtLeastOneChild);
              return;
            }
            ref.invalidate(subscribeControllerProvider);
            _trackMethod(method.kind, plan, targets.length);
            _analytics.track('payment_screen_viewed', {'plan_id': plan.id});
            setState(() {
              _plan = plan;
              _method = method;
              _selectError = null;
              _step = _Step.bankily;
            });
          },
          onContact: () {
            if (plan == null) return;
            if (targets.isEmpty) {
              setState(() => _selectError = l10n.selectAtLeastOneChild);
              return;
            }
            setState(() => _plan = plan);
            _trackMethod('contact', plan, targets.length);
            _submitContact(targets);
          },
        ),
      _Step.bankily => _BankilyStep(
          total: _quote(_plan!, targets.length).totalMru,
          method: _method!,
          phoneController: _phoneController,
          phoneError: _phoneError,
          proof: _proof,
          proofError: _proofError,
          onPickProof: _pickProof,
          serverError: serverError,
          submitting: submitting,
          onSubmit: () => _submitTransfer([for (final s in targets) s.id]),
        ),
      _Step.success => _SuccessStep(
          kind: _successKind!,
          methodName: _method?.name ?? '',
          // Opened with context.go (offer screen) the flow is the only
          // route, so popping did nothing: go to the right home instead.
          onDone: widget.embedded
              ? _reset
              : () => selfMode
                  ? context.goNamed(StudentHomeScreen.name)
                  : context.go(ParentShellScreen.path),
        ),
    };
  }
}

class _SelectStep extends ConsumerWidget {
  const _SelectStep({
    required this.plans,
    required this.plan,
    required this.quoteFor,
    required this.eligibleUnselected,
    required this.students,
    required this.selfMode,
    required this.selectedIds,
    required this.targets,
    required this.embedded,
    required this.submitting,
    required this.errorText,
    required this.onPlan,
    required this.onToggle,
    required this.methods,
    required this.onRetryMethods,
    required this.onMethod,
    required this.onContact,
  });

  final List<Plan> plans;
  final Plan? plan;
  final FamilyQuote Function(Plan plan, int children) quoteFor;

  /// Children who could still join this purchase (not selected, not
  /// already covered) — drives the "add one more and save" nudge.
  final List<Student> eligibleUnselected;
  final List<Student> students;
  final bool selfMode;
  final Set<String> selectedIds;
  final List<Student> targets;
  final bool embedded;
  final bool submitting;
  final String? errorText;
  final ValueChanged<Plan> onPlan;
  final ValueChanged<String> onToggle;

  /// Payment methods to offer (loading / failed: none shown, manual
  /// payment stays available).
  final AsyncValue<List<PaymentMethod>> methods;
  final VoidCallback onRetryMethods;
  final ValueChanged<PaymentMethod> onMethod;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool isArabic = context.isArabicLocale;
    final Map<String, Subscription> subs = selfMode
        ? const {}
        : ref.watch(latestSubscriptionsByStudentProvider).valueOrNull ??
            const {};

    if (plans.isEmpty) {
      return EmptyState(
        icon: Icons.credit_card_off_outlined,
        title: l10n.noPlans,
      );
    }
    final Plan current = plan!;
    final FamilyQuote quote = quoteFor(current, targets.length);
    final AppSettings? settings = ref.watch(appSettingsProvider).valueOrNull;
    String pct(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    final bool familyOn = !selfMode &&
        (settings?.familyDiscountEnabled ?? false) &&
        students.length >= 2;
    // What adding one more child would save (on top of today's saving).
    final Student? nudgeChild = eligibleUnselected.firstOrNull;
    final double nudgeSaving = targets.isEmpty
        ? 0
        : quoteFor(current, targets.length + 1).savingMru - quote.savingMru;
    final bool showNudge = familyOn && nudgeChild != null && nudgeSaving > 0;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.screen,
        0,
        DirasstySpace.screen,
        DirasstySpace.xxl,
      ),
      children: [
        Text(l10n.subscription, style: type.title),
        const SizedBox(height: DirasstySpace.xs),
        Text(
          l10n.subscriptionIntro,
          style: type.bodySmall.copyWith(color: DirasstyColors.textMuted),
        ),
        const SizedBox(height: DirasstySpace.xl),
        for (final Plan p in plans) ...[
          _PlanCard(
            plan: p,
            selected: p.id == current.id,
            onTap: () => onPlan(p),
          ),
          const SizedBox(height: DirasstySpace.md),
        ],
        if (!selfMode) ...[
          const SizedBox(height: DirasstySpace.lg),
          Text(l10n.forWhichChildren, style: type.subheading),
          if (familyOn) ...[
            const SizedBox(height: DirasstySpace.xs),
            Text(
              l10n.familyOfferBanner(
                pct(settings!.familyDiscount2Percent),
                pct(settings.familyDiscount3Percent),
              ),
              style: type.label.copyWith(
                color: DirasstyColors.tealDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: DirasstySpace.md),
          if (students.isEmpty)
            EmptyState(
              icon: Icons.family_restroom_rounded,
              title: l10n.noChildrenTitle,
            )
          else
            DirasstyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (int i, Student s) in students.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    _ChildCheckRow(
                      student: s,
                      subscription: subs[s.id],
                      checked: selectedIds.contains(s.id),
                      onTap: () => onToggle(s.id),
                    ),
                  ],
                ],
              ),
            ),
        ],
        if (showNudge) ...[
          const SizedBox(height: DirasstySpace.md),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.lg,
              DirasstySpace.sm,
              DirasstySpace.sm,
              DirasstySpace.sm,
            ),
            decoration: const BoxDecoration(
              color: DirasstyColors.goldTint,
              borderRadius: DirasstyRadius.cardR,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 20,
                  color: DirasstyColors.goldStroke,
                ),
                const SizedBox(width: DirasstySpace.sm),
                Expanded(
                  child: Text(
                    l10n.addChildForDiscount(
                      nudgeChild.name,
                      nudgeSaving.toStringAsFixed(0),
                    ),
                    style: type.label.copyWith(
                      color: DirasstyColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DirasstyButton(
                  label: l10n.addAction,
                  variant: DirasstyButtonVariant.ink,
                  compact: true,
                  expand: false,
                  onPressed: () => onToggle(nudgeChild.id),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: DirasstySpace.xl),
        DirasstyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (targets.isNotEmpty) ...[
                _SummaryLine(
                  label: l10n.childrenTimesPlan(
                    targets.length,
                    current.name(isArabic),
                  ),
                  value: l10n.priceMru(quote.subtotalMru.toStringAsFixed(0)),
                ),
                if (quote.familyDiscountPercent > 0) ...[
                  const SizedBox(height: DirasstySpace.sm),
                  _SummaryLine(
                    label: l10n
                        .familyDiscountLine(pct(quote.familyDiscountPercent)),
                    value:
                        l10n.minusPriceMru(quote.savingMru.toStringAsFixed(0)),
                    color: DirasstyColors.teal,
                  ),
                ],
                const Divider(height: DirasstySpace.xl),
              ],
              _SummaryLine(
                label: l10n.total,
                value: l10n.priceMru(quote.totalMru.toStringAsFixed(0)),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.md),
        const PromoCodeField(),
        if (errorText != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            errorText!,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
        ],
        const SizedBox(height: DirasstySpace.xl),
        ...switch (methods) {
          AsyncData(value: final list) when list.isNotEmpty => [
              Text(l10n.choosePaymentMethod, style: type.label),
              const SizedBox(height: DirasstySpace.sm),
              for (final PaymentMethod m in list) ...[
                _MethodTile(
                  method: m,
                  label: l10n.payWithMethod(m.name),
                  onTap: submitting ? null : () => onMethod(m),
                ),
                const SizedBox(height: DirasstySpace.sm),
              ],
            ],
          AsyncLoading() => [
              const Skeleton(height: 56, radius: DirasstyRadius.card),
              const SizedBox(height: DirasstySpace.sm),
            ],
          AsyncError() => [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onRetryMethods,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          _ => const <Widget>[],
        },
        DirasstyButton(
          label: l10n.payByContact,
          icon: Icons.chat_outlined,
          variant: DirasstyButtonVariant.quiet,
          onPressed: submitting ? null : onContact,
        ),
        if (embedded && !selfMode)
          DirasstyButton(
            label: l10n.seeMySubscriptions,
            variant: DirasstyButtonVariant.quiet,
            onPressed: () => context.push(SubscriptionScreen.path),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String pct = plan.discountPercent.toStringAsFixed(0);
    final String subtitle = plan.key == 'monthly' && !plan.hasDiscount
        ? l10n.planNoCommitment
        : plan.hasDiscount
            ? l10n.planDaysDiscount(plan.durationDays, pct)
            : l10n.planDays(plan.durationDays);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? DirasstyColors.tealTint : DirasstyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: DirasstyRadius.cardR,
          side: BorderSide(
            color: selected ? DirasstyColors.teal : DirasstyColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: DirasstyRadius.cardR,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
            child: Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: DirasstySpace.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.name(context.isArabicLocale),
                            style: type.subheading.copyWith(fontSize: 16),
                          ),
                          if (plan.key == 'quarterly')
                            DirasstyChip(
                              label: l10n.popular,
                              variant: DirasstyChipVariant.gold,
                              dense: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: type.label.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DirasstySpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (plan.hasDiscount)
                      Text(
                        l10n.priceMru(plan.priceMru.toStringAsFixed(0)),
                        style: type.label.copyWith(
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      l10n.priceMru(plan.effectivePriceMru.toStringAsFixed(0)),
                      style: type.subheading
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? DirasstyColors.teal : DirasstyColors.idle,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: DirasstyColors.teal,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _ChildCheckRow extends ConsumerWidget {
  const _ChildCheckRow({
    required this.student,
    required this.subscription,
    required this.checked,
    required this.onTap,
  });

  final Student student;
  final Subscription? subscription;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final Subscription? sub = subscription;
    final String status = switch (sub) {
      null => l10n.childNoPlan,
      _ when sub.status == SubscriptionStatus.pending => l10n.childInReview,
      _ when sub.status == SubscriptionStatus.trial && sub.grantsAccess =>
        l10n.childTrialDaysLeft(sub.daysLeftInTrial),
      _ when sub.grantsAccess && sub.expiresAt != null =>
        l10n.childActiveUntil(DirasstyDates.dayMonthYear(sub.expiresAt!, lang)),
      _ => l10n.childNoPlan,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: DirasstySpace.lg,
          vertical: DirasstySpace.md,
        ),
        child: Row(
          children: [
            Semantics(
              checked: checked,
              child: AnimatedContainer(
                duration:
                    context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? DirasstyColors.teal : DirasstyColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked ? DirasstyColors.teal : DirasstyColors.idle,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: DirasstySpace.md),
            ChildAvatar(name: student.name, size: 40),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: type.subheading.copyWith(fontSize: 14),
                  ),
                  Text(
                    '${gradeName(ref, student.grade)} · $status',
                    style: type.label.copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.strong = false,
    this.color,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final TextStyle base = strong
        ? type.subheading.copyWith(fontSize: 18, fontWeight: FontWeight.w800)
        : type.bodySmall;
    final TextStyle style = color == null
        ? base
        : base.copyWith(color: color, fontWeight: FontWeight.w700);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _BankilyStep extends StatelessWidget {
  const _BankilyStep({
    required this.total,
    required this.method,
    required this.phoneController,
    required this.phoneError,
    required this.proof,
    required this.proofError,
    required this.onPickProof,
    required this.serverError,
    required this.submitting,
    required this.onSubmit,
  });

  final double total;

  /// The chosen payment method: its name and the number to pay to.
  final PaymentMethod method;
  final TextEditingController phoneController;
  final String? phoneError;
  final Uint8List? proof;
  final String? proofError;
  final VoidCallback onPickProof;
  final String? serverError;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String merchant = method.accountNumber;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.screen,
        0,
        DirasstySpace.screen,
        DirasstySpace.xxl,
      ),
      children: [
        Row(
          children: [
            _MethodLogo(method: method, size: 40),
            const SizedBox(width: DirasstySpace.md),
            Expanded(
              child: Text(
                l10n.paymentMethodTitle(method.name),
                style: type.title,
              ),
            ),
          ],
        ),
        const SizedBox(height: DirasstySpace.xl),
        Container(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
          decoration: const BoxDecoration(
            color: DirasstyColors.ink,
            borderRadius: DirasstyRadius.cardR,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.amountToSend,
                style:
                    type.label.copyWith(color: DirasstyColors.textOnDarkMuted),
              ),
              const SizedBox(height: DirasstySpace.xs),
              Text(
                l10n.priceMru(total.toStringAsFixed(0)),
                style: type.title.copyWith(
                  color: DirasstyColors.gold,
                  fontSize: 30,
                  fontFamily: 'Inter',
                ),
              ),
              if (merchant.isNotEmpty) ...[
                const Divider(height: DirasstySpace.xl, color: Colors.white24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.methodNumber(method.name),
                            style: type.label.copyWith(
                              color: DirasstyColors.textOnDarkMuted,
                            ),
                          ),
                          Text(
                            merchant,
                            textDirection: TextDirection.ltr,
                            style: type.subheading.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copied,
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: merchant));
                        if (context.mounted) {
                          showDirasstySnackBar(context, l10n.copied);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (merchant.isEmpty) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            l10n.bankilyNumberSoon,
            style: type.label.copyWith(color: DirasstyColors.goldStroke),
          ),
        ],
        const SizedBox(height: DirasstySpace.xl),
        for (final (int i, String step) in [
          l10n.methodStep1(method.name),
          l10n.bankilyStep2,
          l10n.bankilyStep3,
        ].indexed) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DirasstyColors.tealTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: type.label.copyWith(
                    color: DirasstyColors.teal,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(child: Text(step, style: type.bodySmall)),
            ],
          ),
          const SizedBox(height: DirasstySpace.md),
        ],
        const SizedBox(height: DirasstySpace.md),
        DirasstyTextField(
          label: l10n.methodPhone,
          controller: phoneController,
          phonePrefix: true,
          errorText: phoneError,
        ),
        const SizedBox(height: DirasstySpace.lg),
        _ProofPicker(proof: proof, error: proofError, onPick: onPickProof),
        if (serverError != null) ...[
          const SizedBox(height: DirasstySpace.md),
          Text(
            serverError!,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
        ],
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(
          label: l10n.confirmPayment,
          loading: submitting,
          onPressed: onSubmit,
        ),
        const SizedBox(height: DirasstySpace.md),
        Text(
          l10n.bankilyVerifyNote,
          textAlign: TextAlign.center,
          style: type.label.copyWith(fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    required this.kind,
    required this.methodName,
    required this.onDone,
  });

  final _SuccessKind kind;
  final String methodName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool bankily = kind == _SuccessKind.bankily;
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
      children: [
        const SizedBox(height: DirasstySpace.xxl),
        Center(
          child: IconBadge(
            icon: bankily ? Icons.hourglass_top_rounded : Icons.chat_rounded,
            size: 88,
            background: DirasstyColors.goldTint,
            foreground: DirasstyColors.ink,
          ),
        ),
        const SizedBox(height: DirasstySpace.xl),
        Text(
          bankily ? l10n.paymentSentTitle : l10n.contactSentTitle,
          textAlign: TextAlign.center,
          style: type.title,
        ),
        const SizedBox(height: DirasstySpace.sm),
        Text(
          bankily
              ? l10n.paymentSentBodyMethod(methodName)
              : l10n.contactSentBody,
          textAlign: TextAlign.center,
          style: type.body.copyWith(color: DirasstyColors.textMuted),
        ),
        const SizedBox(height: DirasstySpace.xxl),
        DirasstyButton(label: l10n.done, onPressed: onDone),
      ],
    );
  }
}

class _SelectSkeleton extends StatelessWidget {
  const _SelectSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Skeleton(height: 28, width: 180),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 76, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 76, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 76, radius: DirasstyRadius.card),
      ],
    );
  }
}

/// "Capture d'écran du paiement": an empty dashed drop zone, then the
/// picked screenshot's preview with "Changer".
class _ProofPicker extends StatelessWidget {
  const _ProofPicker({
    required this.proof,
    required this.error,
    required this.onPick,
  });

  final Uint8List? proof;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Color border = error != null
        ? DirasstyColors.error
        : proof != null
            ? DirasstyColors.teal
            : DirasstyColors.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.paymentProof, style: type.label),
        const SizedBox(height: DirasstySpace.sm),
        Material(
          color:
              proof != null ? DirasstyColors.tealTint : DirasstyColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: DirasstyRadius.cardR,
            side: BorderSide(color: border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPick,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
              child: proof == null
                  ? Column(
                      children: [
                        const SizedBox(height: DirasstySpace.sm),
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 36,
                          color: DirasstyColors.teal,
                        ),
                        const SizedBox(height: DirasstySpace.sm),
                        Text(
                          l10n.addPaymentProof,
                          style: type.subheading.copyWith(
                            color: DirasstyColors.teal,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.paymentProofHintGeneric,
                          textAlign: TextAlign.center,
                          style:
                              type.label.copyWith(fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: DirasstySpace.sm),
                      ],
                    )
                  : Row(
                      children: [
                        ClipRRect(
                          borderRadius: DirasstyRadius.smallR,
                          child: Image.memory(
                            proof!,
                            width: 64,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: DirasstySpace.md),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: DirasstyColors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: DirasstySpace.xs),
                              Expanded(
                                child: Text(
                                  l10n.paymentProofAdded,
                                  style: type.bodySmall
                                      .copyWith(color: DirasstyColors.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          l10n.changePaymentProof,
                          style:
                              type.label.copyWith(color: DirasstyColors.teal),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: DirasstySpace.xs),
          Text(error!, style: type.label.copyWith(color: DirasstyColors.error)),
        ],
      ],
    );
  }
}

/// A payment method's logo (Admin → Moyens de paiement), or a wallet icon
/// when it has none or the image can't load.
class _MethodLogo extends StatelessWidget {
  const _MethodLogo({required this.method, required this.size});

  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(
      Icons.account_balance_wallet_rounded,
      size: size * 0.6,
      color: DirasstyColors.teal,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DirasstyColors.tealTint,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: method.logoUrl == null
          ? fallback
          : Image.network(
              method.logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

/// One payment method on step 1: logo, "Payer avec …", chevron.
class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.label,
    required this.onTap,
  });

  final PaymentMethod method;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Material(
      color: DirasstyColors.surface,
      borderRadius: DirasstyRadius.cardR,
      child: InkWell(
        borderRadius: DirasstyRadius.cardR,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DirasstySpace.lg,
            vertical: DirasstySpace.md,
          ),
          decoration: BoxDecoration(
            borderRadius: DirasstyRadius.cardR,
            border: Border.all(color: DirasstyColors.line),
          ),
          child: Row(
            children: [
              _MethodLogo(method: method, size: 36),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Text(
                  label,
                  style: type.subheading.copyWith(fontSize: 16),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DirasstyColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
