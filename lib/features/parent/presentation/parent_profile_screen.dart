import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/i18n/widgets/language_picker.dart';
import '../../../core/models/parent.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/pin_entry.dart';
import '../../profile/presentation/about_screen.dart';
import '../../profile/presentation/delete_account_screen.dart';
import '../../profile/presentation/faq_screen.dart';
import '../../profile/presentation/widgets/profile_rows.dart';
import '../application/parent_providers.dart';

/// The parent's Profil tab — the student Profile's layout (identity card,
/// grouped rows) with a parent header (name + WhatsApp number): language,
/// help (FAQ, WhatsApp support, rate, share, about), log out, delete.
///
/// design_handoff Profile.dc.html (parent variant) · DESIGN_SPEC §4.
class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Parent> parent = ref.watch(currentParentProvider);

    return SafeArea(
      child: parent.when(
        loading: () => ListView(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
          children: const [
            Skeleton(height: 28, width: 120),
            SizedBox(height: DirasstySpace.lg),
            Skeleton(height: 96, radius: DirasstyRadius.card),
            SizedBox(height: DirasstySpace.lg),
            Skeleton(height: 170, radius: DirasstyRadius.card),
          ],
        ),
        error: (_, __) => ErrorState(
          title: l10n.errGeneric,
          onRetry: () => ref.invalidate(currentParentProvider),
        ),
        data: (p) => _ParentProfileBody(parent: p),
      ),
    );
  }
}

class _ParentProfileBody extends ConsumerWidget {
  const _ParentProfileBody({required this.parent});

  final Parent parent;

  /// The stored number may or may not carry the 222 country code.
  String get _localPhone {
    final String digits = parent.phone.replaceAll(RegExp(r'\D'), '');
    return digits.length > 8 && digits.startsWith('222')
        ? digits.substring(3)
        : digits;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AppLang lang = ref.watch(appLanguageProvider);
    final String initial = parent.name.trim().isEmpty
        ? '?'
        : parent.name.trim().characters.first.toUpperCase();

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DirasstySpace.screen,
        DirasstySpace.xl,
        DirasstySpace.screen,
        DirasstySpace.xl,
      ),
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
                  color: DirasstyColors.tealTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: type.title.copyWith(color: DirasstyColors.teal),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.name,
                      style: type.heading.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.parentSpace} · ${formatMauritanianPhone(_localPhone)}',
                      style: type.label.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.lg),
        ProfileGroup(
          rows: [
            ProfileRow(
              icon: Icons.language_rounded,
              title: l10n.language,
              subtitle:
                  lang.isArabic ? l10n.languageArabic : l10n.languageFrench,
              trailing: DirasstyChip(
                label: lang.isArabic ? 'عربي' : 'FR',
                dense: true,
              ),
              onTap: () => showLanguagePickerSheet(context, ref),
            ),
          ],
        ),
        const SizedBox(height: DirasstySpace.lg),
        ProfileGroup(
          rows: [
            ProfileRow(
              icon: Icons.help_outline_rounded,
              title: l10n.faq,
              onTap: () => context.push(FaqScreen.path),
            ),
            ProfileRow(
              icon: Icons.chat_outlined,
              title: l10n.whatsappSupport,
              onTap: () => contactSupport(context),
            ),
            ProfileRow(
              icon: Icons.star_outline_rounded,
              title: l10n.rateApp,
              onTap: () => rateApp(context),
            ),
            ProfileRow(
              icon: Icons.share_outlined,
              title: l10n.shareApp,
              onTap: () => shareApp(context),
            ),
            ProfileRow(
              icon: Icons.info_outline_rounded,
              title: l10n.about,
              onTap: () => context.push(AboutScreen.path),
            ),
          ],
        ),
        const SizedBox(height: DirasstySpace.lg),
        ProfileGroup(
          rows: [
            ProfileRow(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            ProfileRow(
              icon: Icons.delete_outline_rounded,
              title: l10n.deleteAccount,
              destructive: true,
              onTap: () => context.push(DeleteAccountScreen.path),
            ),
          ],
        ),
      ],
    );
  }
}
