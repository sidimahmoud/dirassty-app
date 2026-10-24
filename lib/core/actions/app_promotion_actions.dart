import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/subscription/application/subscription_providers.dart';
import '../config/app_promotion_config.dart';
import '../config/support_config.dart';

/// Support's WhatsApp number: the one set in Admin → Paramètres (part of
/// the settings row the app already loads — no extra request), else the
/// built-in [SupportConfig.whatsappNumber] (settings not loaded within 2 s,
/// offline, or not set).
Future<String> supportWhatsappNumber(BuildContext context) async {
  final ProviderContainer container =
      ProviderScope.containerOf(context, listen: false);
  try {
    final String? number = (await container
            .read(appSettingsProvider.future)
            .timeout(const Duration(seconds: 2)))
        .supportWhatsappNumber;
    if (number != null && number.isNotEmpty) return number;
  } catch (_) {}
  return SupportConfig.whatsappNumber;
}

/// Shared by both the student and parent Profile screens — support
/// contact, sharing, and rating the app aren't role-specific, so these
/// live here once instead of being duplicated (or, worse, only ever
/// living privately in whichever screen was built first). Always
/// available, no parental gate.
Future<void> contactSupport(BuildContext context) async {
  final String number = await supportWhatsappNumber(context);
  if (!context.mounted) return;
  final Uri uri = Uri.https('wa.me', '/$number', {
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
  await launchUrl(
    Uri.parse(AppPromotionConfig.officialEducationUrl),
    mode: LaunchMode.externalApplication,
  );
}

Future<void> openPrivacyPolicy(BuildContext context) async {
  await launchUrl(
    Uri.parse(AppPromotionConfig.privacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
}
