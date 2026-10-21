import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/pin_login_form.dart';

/// Parent login: WhatsApp number (+222) + 4-digit PIN on the custom
/// keypad. On success the router's auth-redirect gate takes over.
///
/// Deviation from ParentLogin.dc.html: the "Nouveau téléphone ? … code
/// WhatsApp" card is left out — sign-in is phone + PIN only, there is no
/// new-device verification step to promise. TODO(api): add new-device
/// WhatsApp verification, then restore the card.
///
/// design_handoff ParentLogin.dc.html · DESIGN_SPEC §4 "Parent login".
class ParentLoginScreen extends ConsumerStatefulWidget {
  const ParentLoginScreen({super.key});

  static const String path = '/login/parent';
  static const String name = 'parentLogin';

  @override
  ConsumerState<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends ConsumerState<ParentLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    return PinLoginForm(
      limiterScope: 'parent',
      heading:
          AuthHeading(title: l10n.parentLoginTitle, body: l10n.parentLoginBody),
      identityField: DirasstyTextField(
        label: l10n.whatsappNumber,
        controller: _phoneController,
        phonePrefix: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
      ),
      identityFilled: _phoneController.text.trim().length >= 8,
      submitLabel: l10n.continueAction,
      wrongCredentialsMessage: l10n.wrongParentCredentials,
      onSubmit: (pin) => ref
          .read(authControllerProvider.notifier)
          .signInParent(phone: _phoneController.text.trim(), pin: pin),
      onForgotPin: () async {
        final bool? openSupport = await showDirasstyDialog<bool>(
          context,
          icon: Icons.lock_reset_rounded,
          title: l10n.forgotPin,
          message: l10n.forgotPinParentBody,
          actions: [
            DirasstyDialogAction(label: l10n.whatsappSupport, value: true),
            DirasstyDialogAction(
              label: l10n.close,
              value: false,
              variant: DirasstyButtonVariant.quiet,
            ),
          ],
        );
        if (openSupport == true && context.mounted) {
          await contactSupport(context);
        }
      },
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.noAccountYet, style: type.bodySmall),
          TextButton(
            onPressed: () => context.push(RegisterScreen.pathFor('parent')),
            child: Text(l10n.createAccount),
          ),
        ],
      ),
    );
  }
}
