import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';

/// Shown to a parent who just verified their phone but has no `parents`
/// row yet — mirrors the web app's post-OTP redirect to `/onboarding`.
/// The real registration form (name, add a child) is a later phase; this
/// only proves that branch of the auth flow actually gets reached.
class ParentOnboardingPlaceholderScreen extends ConsumerWidget {
  const ParentOnboardingPlaceholderScreen({super.key});

  static const String path = '/parent/onboarding';
  static const String name = 'parentOnboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppLocalizations.of(context).logout,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(DirasstySpace.xl),
          child: Text(
            'Numéro vérifié ✅\nLa création de profil arrive dans une '
            'prochaine phase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DirasstyColors.textMuted),
          ),
        ),
      ),
    );
  }
}
