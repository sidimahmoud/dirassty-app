import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'choose_role_screen.dart';
import 'parent_login_screen.dart';
import 'student_login_screen.dart';
import 'widgets/auth_scaffold.dart';

/// First screen for a signed-out user: language switch, who-are-you role
/// cards (each opens that role's login), and "Créer un compte" (→
/// [ChooseRoleScreen]: student or parent).
///
/// design_handoff/design/screens/Welcome.dc.html · DESIGN_SPEC §4
/// "Welcome".
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const String path = '/';
  static const String name = 'welcome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    return AuthScaffold(
      showBack: false,
      sidePadding: DirasstySpace.xl,
      gap: DirasstySpace.xxl,
      children: [
        Row(
          children: [
            Semantics(
              label: 'Dirassty',
              image: true,
              child: SvgPicture.asset('assets/logo/logo_horizontal.svg',
                  height: 44),
            ),
            const Spacer(),
            const _LanguageSwitch(),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: DirasstySpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.welcomeTitle, style: type.display),
              const SizedBox(height: DirasstySpace.sm),
              Text(l10n.welcomeBody,
                  style: type.body.copyWith(color: DirasstyColors.textMuted)),
            ],
          ),
        ),
        // Registering is the default path for a new visitor…
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DirasstyButton(
              label: l10n.createAccount,
              onPressed: () => context.pushNamed(ChooseRoleScreen.name),
            ),
            const SizedBox(height: DirasstySpace.md),
            Text(
              l10n.trialLine,
              textAlign: TextAlign.center,
              style: type.label.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ],
      // …and logging in sits at the bottom for those who already have an
      // account.
      bottom: [
        Text(l10n.signInWho,
            textAlign: TextAlign.center, style: type.subheading),
        _RoleCard(
          icon: Icons.school_rounded,
          title: l10n.iAmStudent,
          subtitle: l10n.iAmStudentSub,
          onTap: () => context.pushNamed(StudentLoginScreen.name),
        ),
        _RoleCard(
          icon: Icons.family_restroom_rounded,
          title: l10n.iAmParent,
          subtitle: l10n.iAmParentSub,
          onTap: () => context.pushNamed(ParentLoginScreen.name),
        ),
      ],
    );
  }
}

/// FR / عربي pill switch — changes the locale immediately and persists
/// it (appLanguageProvider → shared_preferences).
class _LanguageSwitch extends ConsumerWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLang current = ref.watch(appLanguageProvider);
    Widget option(AppLang lang, String label, TextStyle style) {
      final bool selected = current == lang;
      return Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: DirasstyRadius.pillR,
          onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(lang),
          child: AnimatedContainer(
            duration: context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
            height: 36,
            constraints: const BoxConstraints(minWidth: DirasstySize.minTouch),
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: DirasstySpace.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? DirasstyColors.surface : Colors.transparent,
              borderRadius: DirasstyRadius.pillR,
              boxShadow: selected ? DirasstyShadow.level1 : null,
            ),
            child: Text(
              label,
              style: style.copyWith(
                  color: selected ? DirasstyColors.ink : DirasstyColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(DirasstySpace.xs),
      decoration: const BoxDecoration(
          color: DirasstyColors.track, borderRadius: DirasstyRadius.pillR),
      // The switch itself never mirrors: FR is always the first option.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(AppLang.fr, 'FR',
                DirasstyType(false).label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            option(
                AppLang.ar,
                'عربي',
                DirasstyType(true)
                    .label
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Material(
      color: DirasstyColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: DirasstyRadius.cardR,
        side: const BorderSide(color: DirasstyColors.line, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: DirasstySpace.lg, vertical: DirasstySpace.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: DirasstyColors.tealTint,
                  borderRadius: DirasstyRadius.cardR,
                ),
                child: Icon(icon, color: DirasstyColors.teal),
              ),
              const SizedBox(width: DirasstySpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: type.subheading.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: type.bodySmall),
                  ],
                ),
              ),
              // Explicit "Se connecter" so the cards read as the login
              // entry points, not a role quiz before registration.
              Text(
                AppLocalizations.of(context).signIn,
                style: type.label.copyWith(
                    color: DirasstyColors.teal, fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.chevron_right_rounded, color: DirasstyColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
