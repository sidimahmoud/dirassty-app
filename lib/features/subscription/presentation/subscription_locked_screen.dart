import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/security/parental_gate.dart';

import '../../../core/models/student.dart';
import '../../../core/models/subscription.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../focus/presentation/focus_blocked_dialog.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../student/application/student_providers.dart';
import '../application/subscription_providers.dart';
import 'subscribe_flow_screen.dart';

/// Shown instead of any course / exercise / helper screen without access
/// (see the router's redirect gate): no plan yet, a payment being checked
/// or arranged, or an ended trial / plan — each with its own message.
/// Progress is kept.
///
/// The router also lands here when the access check itself failed (no
/// connection, an error): so on open it re-checks once and lets the
/// student straight back in if access is actually valid, and when the
/// check keeps failing it says so — never "trial ended" for a student who
/// may well have a paid plan. Trial wording only for a real trial row.
///
/// Actions: tell a parent on WhatsApp (share sheet with a prefilled
/// message — the app doesn't know the parent's number), pick a plan
/// oneself (any student can, see 038_students_self_manage_subscription),
/// "Déjà payé ? Actualiser", log out.
///
/// design_handoff SubscriptionLocked.dc.html · DESIGN_SPEC §4.
class SubscriptionLockedScreen extends ConsumerStatefulWidget {
  const SubscriptionLockedScreen({super.key});

  static const String path = '/subscription-locked';
  static const String name = 'subscriptionLocked';

  @override
  ConsumerState<SubscriptionLockedScreen> createState() =>
      _SubscriptionLockedScreenState();
}

class _SubscriptionLockedScreenState
    extends ConsumerState<SubscriptionLockedScreen> {
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recheck());
  }

  /// Fresh access check (drops any cached result, incl. a cached
  /// failure); sends the student home when access is in fact valid.
  Future<void> _recheck() async {
    try {
      final Student student = await ref.read(currentStudentProvider.future);
      ref.invalidate(subscriptionForStudentProvider(student.id));
      ref.invalidate(studentHasAccessProvider(student.id));
      final bool hasAccess =
          await ref.read(studentHasAccessProvider(student.id).future);
      if (hasAccess && mounted) context.goNamed(StudentHomeScreen.name);
    } catch (_) {
      ref.invalidate(currentStudentProvider);
    }
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final Student student = await ref.read(currentStudentProvider.future);
      ref.invalidate(subscriptionForStudentProvider(student.id));
      ref.invalidate(studentHasAccessProvider(student.id));
      if (!mounted) return;
      context.goNamed(StudentHomeScreen.name);
    } catch (_) {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _notifyParent() async {
    if (!await passParentalGate(context) || !mounted) return;
    final Uri uri = Uri.https('wa.me', '/',
        {'text': AppLocalizations.of(context).parentWhatsappMessage});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _signOut() {
    if (blockedByFocus(context, ref)) return;
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<Student> studentAsync = ref.watch(currentStudentProvider);
    final Student? student = studentAsync.valueOrNull;
    final AsyncValue<Subscription?>? subAsync = student == null
        ? null
        : ref.watch(subscriptionForStudentProvider(student.id));
    final Subscription? sub = subAsync?.valueOrNull;
    final bool checking =
        studentAsync.isLoading || (subAsync?.isLoading ?? false);
    final bool checkFailed =
        studentAsync.hasError || (subAsync?.hasError ?? false);
    // A brand-new account (no plan yet), a payment being checked, a
    // manual payment being arranged, an ended trial, an ended plan.
    final (String title, String body) = checkFailed
        ? (l10n.subscriptionCheckFailedTitle, l10n.subscriptionCheckFailedBody)
        : switch (sub?.status) {
            null => (l10n.lockedNoPlanTitle, l10n.lockedNoPlanBody),
            SubscriptionStatus.pending => (
                l10n.lockedPendingTitle,
                l10n.lockedPendingBody
              ),
            SubscriptionStatus.unpaid => (
                l10n.lockedManualTitle,
                l10n.lockedManualBody
              ),
            SubscriptionStatus.trial => (l10n.trialEnded, l10n.trialEndedBody),
            _ => (l10n.subscriptionEndedTitle, l10n.trialEndedBody),
          };
    final bool neverSubscribed = !checkFailed && sub == null;

    void goHome() => context.goNamed(StudentHomeScreen.name);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: goHome),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.xl,
              DirasstySpace.sm, DirasstySpace.xl, DirasstySpace.xl),
          children: [
            const Center(
              child: IconBadge(
                icon: Icons.lock_clock_rounded,
                size: 112,
                background: DirasstyColors.goldTint,
                foreground: DirasstyColors.goldStroke,
              ),
            ),
            const SizedBox(height: DirasstySpace.screen),
            if (checking)
              const Center(child: CircularProgressIndicator())
            else
              Text(
                title,
                textAlign: TextAlign.center,
                style: type.title.copyWith(fontSize: 28),
              ),
            const SizedBox(height: DirasstySpace.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: type.body.copyWith(color: DirasstyColors.textMuted),
            ),
            // "Nothing is lost" only makes sense once there was a plan.
            if (student != null && !neverSubscribed) ...[
              const SizedBox(height: DirasstySpace.xl),
              DirasstyCard(
                variant: DirasstyCardVariant.shadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: DirasstyColors.teal, size: 20),
                        const SizedBox(width: DirasstySpace.md),
                        Expanded(
                            child: Text(l10n.nothingLost,
                                style: type.subheading.copyWith(fontSize: 14))),
                      ],
                    ),
                    const SizedBox(height: DirasstySpace.sm),
                    Text(
                      l10n.nothingLostBody(student.streak, student.xpTotal),
                      style:
                          type.bodySmall.copyWith(color: DirasstyColors.text),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DirasstySpace.xxl),
            DirasstyButton(
                label: l10n.notifyParent,
                icon: Icons.chat_rounded,
                onPressed: _notifyParent),
            const SizedBox(height: DirasstySpace.md),
            DirasstyButton(
              label: l10n.subscribeMyself,
              variant: DirasstyButtonVariant.gold,
              onPressed: () => context.push(SubscribeFlowScreen.path),
            ),
            const SizedBox(height: DirasstySpace.md),
            DirasstyButton(
              label: l10n.alreadyPaid,
              icon: Icons.refresh_rounded,
              variant: DirasstyButtonVariant.secondary,
              loading: _retrying,
              onPressed: _retry,
            ),
            const SizedBox(height: DirasstySpace.md),
            DirasstyButton(
              label: l10n.backToHome,
              icon: Icons.home_rounded,
              variant: DirasstyButtonVariant.quiet,
              onPressed: goHome,
            ),
            const SizedBox(height: DirasstySpace.sm),
            TextButton(
              onPressed: _signOut,
              child: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }
}
