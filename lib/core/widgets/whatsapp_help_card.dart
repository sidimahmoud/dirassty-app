import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../actions/app_promotion_actions.dart';
import '../theme/dirassty_theme.dart';
import 'dirassty/dirassty_widgets.dart';

/// "Besoin d'aide ?" on the student and parent home screens: opens a
/// WhatsApp chat with support (number from Admin → Paramètres, see
/// [contactSupport]).
///
/// General help only — App Store rule 3.1.1 forbids pointing iOS users to
/// another way to pay, so the wording and the prefilled message never
/// mention plans or payment, and this card must not sit on a lock screen.
class WhatsAppHelpCard extends StatelessWidget {
  const WhatsAppHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      onTap: () => contactSupport(context),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/whatsapp.svg',
            width: 40,
            height: 40,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: DirasstySpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.needHelpTitle, style: type.subheading),
                const SizedBox(height: DirasstySpace.xs),
                Text(l10n.needHelpBody, style: type.bodySmall),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: DirasstyColors.textMuted,
          ),
        ],
      ),
    );
  }
}
