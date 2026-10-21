import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';
import 'parent_shell_screen.dart';

/// What [AddChildScreen] hands to [ChildCreatedScreen] (route `extra`).
/// The PIN travels in memory only so the parent can share / copy the
/// credentials once; it's never shown on screen.
class ChildCreatedArgs {
  const ChildCreatedArgs({
    required this.studentId,
    required this.name,
    required this.username,
    required this.pin,
  });

  final String studentId;
  final String name;
  final String username;
  final String pin;
}

/// Step 2 of "Ajouter un enfant": the new login on an ink card, then
/// Share via WhatsApp / Copy / back home. The child already has a free
/// trial, and the home card offers "S'abonner pour {prénom}".
///
/// Deviation from AddChildSuccess.dc.html: no NJH-XXXX invite code card
/// — the app has no invitations; the parent shares the username + PIN.
///
/// design_handoff AddChildSuccess.dc.html · DESIGN_SPEC §4 "Parent space".
class ChildCreatedScreen extends StatelessWidget {
  const ChildCreatedScreen({required this.args, super.key});

  static const String path = '/parent/child-created';
  static const String name = 'childCreated';

  final ChildCreatedArgs args;

  String _message(AppLocalizations l10n) =>
      l10n.credentialsShareMessage(args.username, args.pin);

  Future<void> _share(AppLocalizations l10n) async {
    await launchUrl(
      Uri.https('wa.me', '/', {'text': _message(l10n)}),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _message(l10n)));
    if (context.mounted) showDirasstySnackBar(context, l10n.credentialsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    return AuthScaffold(
      onBack: () => context.go(ParentShellScreen.path),
      bottom: [
        DirasstyButton(
          label: l10n.shareWhatsapp,
          icon: Icons.chat_rounded,
          onPressed: () => _share(l10n),
        ),
        DirasstyButton(
          label: l10n.copyCredentials,
          icon: Icons.copy_rounded,
          variant: DirasstyButtonVariant.secondary,
          onPressed: () => _copy(context, l10n),
        ),
        DirasstyButton(
          label: l10n.backToHome,
          variant: DirasstyButtonVariant.quiet,
          onPressed: () {
            // Counted once per parent in reports (distinct users).
            ProviderScope.containerOf(context, listen: false)
                .read(appAnalyticsProvider)
                .track('onboarding_completed', {'role': 'parent'});
            context.go(ParentShellScreen.path);
          },
        ),
      ],
      children: [
        Column(
          children: [
            const IconBadge(
              icon: Icons.check_rounded,
              size: 72,
              background: DirasstyColors.teal,
              foreground: Colors.white,
            ),
            const SizedBox(height: DirasstySpace.lg),
            Text(
              l10n.childReady(args.name),
              textAlign: TextAlign.center,
              style: type.title,
            ),
            const SizedBox(height: DirasstySpace.sm),
            Text(
              l10n.giveCredentials,
              textAlign: TextAlign.center,
              style: type.body.copyWith(color: DirasstyColors.textMuted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
          decoration: const BoxDecoration(
            color: DirasstyColors.ink,
            borderRadius: DirasstyRadius.cardR,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CredentialRow(label: l10n.username, value: args.username),
              const Divider(height: DirasstySpace.xl, color: Colors.white24),
              _CredentialRow(label: l10n.pinCode, value: '••••'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: type.label.copyWith(color: DirasstyColors.textOnDarkMuted),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value,
            style: type.subheading.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
