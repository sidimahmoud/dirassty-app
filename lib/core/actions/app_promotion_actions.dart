import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_promotion_config.dart';
import '../config/support_config.dart';
import '../security/parental_gate.dart';

/// Shared by both the student and parent Profile screens — support
/// contact, sharing, and rating the app aren't role-specific, so these
/// live here once instead of being duplicated (or, worse, only ever
/// living privately in whichever screen was built first). Each one
/// leaves the app, so a student session goes through [passParentalGate].
Future<void> contactSupport(BuildContext context) async {
  if (!await passParentalGate(context) || !context.mounted) return;
  final Uri uri = Uri.https('wa.me', '/${SupportConfig.whatsappNumber}', {
    'text': "Bonjour, j'ai besoin d'aide avec l'application Dirassty.",
  });
  final bool launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")),
    );
  }
}

Future<void> shareApp(BuildContext context) async {
  if (!await passParentalGate(context)) return;
  await Share.share(
    "J'apprends avec Dirassty, une appli qui explique le programme "
    'mauritanien en français et en arabe. Essaie-la : '
    '${AppPromotionConfig.shareUrl}',
  );
}

Future<void> rateApp(BuildContext context) async {
  if (!AppPromotionConfig.isPublishedOnAnyStore) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "L'application n'est pas encore disponible sur les stores — reviens bientôt !",
        ),
      ),
    );
    return;
  }
  if (!await passParentalGate(context)) return;
  final Uri uri = AppPromotionConfig.androidPackageName.isNotEmpty
      ? Uri.parse(
          'https://play.google.com/store/apps/details?id=${AppPromotionConfig.androidPackageName}',
        )
      : Uri.parse(
          'https://apps.apple.com/app/id${AppPromotionConfig.iosAppStoreId}',
        );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// The Ministry of Education's website — the official source for the
/// curriculum, the school calendar and the exams.
Future<void> openOfficialEducationSite(BuildContext context) async {
  if (!await passParentalGate(context)) return;
  await launchUrl(
    Uri.parse(AppPromotionConfig.officialEducationUrl),
    mode: LaunchMode.externalApplication,
  );
}

Future<void> openPrivacyPolicy(BuildContext context) async {
  if (!await passParentalGate(context)) return;
  await launchUrl(
    Uri.parse(AppPromotionConfig.privacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
}
