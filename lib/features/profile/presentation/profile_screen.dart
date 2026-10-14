import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/i18n/widgets/language_picker.dart';
import '../../../core/models/grade.dart';
import '../../../core/models/student.dart';
import '../../../core/models/subscription.dart';
import '../../../core/offline/offline_videos_controller.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../courses/application/courses_providers.dart';
import '../../focus/presentation/focus_blocked_dialog.dart';
// import '../../focus/presentation/focus_settings_screen.dart'; // next version
import '../../home/presentation/widgets/student_tab_bar.dart';
import '../../student/application/student_providers.dart';
import '../../subscription/application/subscription_providers.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'downloads_screen.dart';
import 'faq_screen.dart';
import 'widgets/profile_rows.dart';

/// Profile tab (tab 4): identity card, subscription card, then grouped
/// settings — language, downloads, parental control — help (FAQ, WhatsApp
/// support, rate, share, about) and account (log out, delete). During a
/// focus window, log out / delete are blocked with the focus dialog.
///
/// Deviation from Profile.dc.html: no "Réponse en moins de [DÉLAI]" line
/// (no configured value) and no version line (package_info_plus isn't a
/// direct dependency).
///
/// design_handoff Profile.dc.html · DESIGN_SPEC §4 "Profile".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String path = '/profile';
  static const String name = 'profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Student> student = ref.watch(currentStudentProvider);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      bottomNavigationBar: const StudentTabBar(currentIndex: 3),
      body: SafeArea(
        child: student.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: ErrorState(
                title: l10n.profileLoadError,
                onRetry: () => ref.invalidate(currentStudentProvider)),
          ),
          data: (s) => _ProfileBody(student: s),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.student});

  final Student student;

  Future<void> _refresh(WidgetRef ref) async {
    // An admin-activated subscription or a change made elsewhere shows
    // up here without restarting the app.
    ref.invalidate(currentStudentProvider);
    ref.invalidate(subscriptionForStudentProvider(student.id));
    ref.invalidate(studentHasAccessProvider(student.id));
    await ref.read(currentStudentProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AppLang lang = ref.watch(appLanguageProvider);
    final OfflineVideosState offline =
        ref.watch(offlineVideosControllerProvider);
    final int downloadBytes =
        offline.downloads.values.fold(0, (sum, v) => sum + v.sizeBytes);
    final String cycle = switch (gradeCycle(student.grade)) {
      GradeCycle.primaire => l10n.cyclePrimary,
      GradeCycle.college => l10n.cycleMiddle,
      GradeCycle.lycee => l10n.cycleHigh,
    };

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen, DirasstySpace.xl, DirasstySpace.screen, DirasstySpace.xl),
        children: [
          Text(l10n.tabProfile, style: type.title),
          const SizedBox(height: DirasstySpace.lg),
          DirasstyCard(
            variant: DirasstyCardVariant.shadow,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: DirasstyColors.tealTint, shape: BoxShape.circle),
                  child: Text(
                    student.name.trim().isEmpty
                        ? '?'
                        : student.name.trim().characters.first.toUpperCase(),
                    style: type.title.copyWith(color: DirasstyColors.teal),
                  ),
                ),
                const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: type.heading
                              .copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          gradeName(ref, student.grade),
                          cycle,
                          if (student.username != null) '@${student.username}',
                        ].join(' · '),
                        style: type.label.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DirasstySpace.lg),
          _SubscriptionCard(studentId: student.id),
          const SizedBox(height: DirasstySpace.lg),
          ProfileGroup(
            rows: [
              ProfileRow(
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle:
                    lang.isArabic ? l10n.languageArabic : l10n.languageFrench,
                trailing: DirasstyChip(
                    label: lang.isArabic ? 'عربي' : 'FR', dense: true),
                onTap: () {
                  if (blockedByFocus(context, ref)) return;
                  showLanguagePickerSheet(context, ref);
                },
              ),
              ProfileRow(
                icon: Icons.download_for_offline_outlined,
                title: l10n.myDownloads,
                subtitle: offline.downloads.isEmpty
                    ? null
                    : l10n.videosCountSize(offline.downloads.length,
                        '${(downloadBytes / (1024 * 1024)).round()} Mo'),
                onTap: () => context.push(DownloadsScreen.path),
              ),
              // Parental control (focus mode) — not ready, back in the next
              // version.
              // ProfileRow(
              //   icon: Icons.shield_outlined,
              //   title: l10n.parentalControl,
              //   subtitle: l10n.protectedByParent,
              //   onTap: () => context.push(StudentParentalControlScreen.path),
              // ),
            ],
          ),
          const SizedBox(height: DirasstySpace.lg),
          ProfileGroup(
            rows: [
              ProfileRow(
                  icon: Icons.help_outline_rounded,
                  title: l10n.faq,
                  onTap: () => context.push(FaqScreen.path)),
              ProfileRow(
                  icon: Icons.chat_outlined,
                  title: l10n.whatsappSupport,
                  onTap: () => contactSupport(context)),
              ProfileRow(
                  icon: Icons.star_outline_rounded,
                  title: l10n.rateApp,
                  onTap: () => rateApp(context)),
              ProfileRow(
                  icon: Icons.share_outlined,
                  title: l10n.shareApp,
                  onTap: () => shareApp(context)),
              ProfileRow(
                  icon: Icons.info_outline_rounded,
                  title: l10n.about,
                  onTap: () => context.push(AboutScreen.path)),
            ],
          ),
          const SizedBox(height: DirasstySpace.lg),
          ProfileGroup(
            rows: [
              ProfileRow(
                icon: Icons.logout_rounded,
                title: l10n.logout,
                onTap: () {
                  if (blockedByFocus(context, ref)) return;
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
              ProfileRow(
                icon: Icons.delete_outline_rounded,
                title: l10n.deleteAccount,
                destructive: true,
                onTap: () {
                  if (blockedByFocus(context, ref)) return;
                  context.push(DeleteAccountScreen.path);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final AsyncValue<Subscription?> sub =
        ref.watch(subscriptionForStudentProvider(studentId));

    return sub.when(
      loading: () => const Skeleton(height: 96, radius: DirasstyRadius.card),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        final DateTime? ends = s?.expiresAt;
        final (String chip, DirasstyChipVariant variant, String body) =
            switch (s) {
          null => (
              l10n.noSubscription,
              DirasstyChipVariant.neutral,
              l10n.noSubscriptionBody
            ),
          _ when s.grantsAccess && s.status == SubscriptionStatus.trial => (
              l10n.trialDaysLeft(s.daysLeftInTrial),
              DirasstyChipVariant.gold,
              l10n.trialUntil(DirasstyDates.dayMonthYear(s.trialEnds, lang)),
            ),
          _ when s.grantsAccess => (
              l10n.subscriptionActive,
              DirasstyChipVariant.teal,
              ends == null
                  ? ''
                  : l10n.accessUntil(DirasstyDates.dayMonthYear(ends, lang)),
            ),
          _ when s.status == SubscriptionStatus.pending => (
              l10n.statusPending,
              DirasstyChipVariant.gold,
              l10n.pendingBody
            ),
          _ => (
              l10n.statusEnded,
              DirasstyChipVariant.red,
              l10n.noSubscriptionBody
            ),
        };
        final String? planName = s?.plan?.name(context.isArabicLocale);

        return DirasstyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DirasstyChip(label: chip, variant: variant, dense: true),
                  const Spacer(),
                  if (planName != null)
                    Text(planName,
                        style:
                            type.label.copyWith(fontWeight: FontWeight.w400)),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: DirasstySpace.sm),
                Text(body,
                    style: type.bodySmall.copyWith(color: DirasstyColors.text)),
              ],
            ],
          ),
        );
      },
    );
  }
}
