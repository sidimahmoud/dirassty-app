@Tags(['golden'])
library;

import 'package:dirassty/core/theme/dirassty_theme.dart';
import 'package:dirassty/core/widgets/dirassty/dirassty_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/dirassty_harness.dart';

/// Visual regression for the design-system components, in French and
/// Arabic (RTL). Baselines live in goldens/ — create or refresh them with:
///
///   flutter test --update-goldens --tags golden
///
/// then review the PNGs against design_handoff/design/screens/DesignSystem.dc.html.
/// Video/playlist components aren't here: they need Supabase + Riverpod
/// providers and are covered on their screens instead.
void main() {
  for (final Locale locale in [fr, ar]) {
    final String lang = locale.languageCode;

    testWidgets('actions ($lang)', (tester) async {
      await pumpDirassty(
        tester,
        _Gallery(
          children: [
            DirasstyButton(label: 'Primary', onPressed: () {}),
            DirasstyButton(
              label: 'Secondary',
              variant: DirasstyButtonVariant.secondary,
              onPressed: () {},
            ),
            DirasstyButton(
              label: 'Ink',
              variant: DirasstyButtonVariant.ink,
              icon: Icons.arrow_forward_rounded,
              onPressed: () {},
            ),
            DirasstyButton(
              label: 'Gold',
              variant: DirasstyButtonVariant.gold,
              onPressed: () {},
            ),
            DirasstyButton(
              label: 'Quiet',
              variant: DirasstyButtonVariant.quiet,
              onPressed: () {},
            ),
            DirasstyButton(
              label: 'Danger',
              variant: DirasstyButtonVariant.danger,
              onPressed: () {},
            ),
            const DirasstyButton(label: 'Disabled', onPressed: null),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final DirasstyChipVariant v in DirasstyChipVariant.values)
                  DirasstyChip(label: v.name, variant: v),
              ],
            ),
            const Row(
              children: [
                StreakBadge(days: 12),
                SizedBox(width: 12),
                LevelBadge(level: 7),
              ],
            ),
          ],
        ),
        locale: locale,
      );
      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/actions_$lang.png'),
      );
    });

    testWidgets('inputs ($lang)', (tester) async {
      await pumpDirassty(
        tester,
        _Gallery(
          children: [
            const DirasstyTextField(
              label: 'Nom d’utilisateur',
              hint: 'amina.b',
            ),
            const DirasstyTextField(
              label: 'Numéro WhatsApp',
              phonePrefix: true,
              hint: '22 12 34 56',
            ),
            const DirasstyTextField(label: 'Username', errorText: 'Déjà pris'),
            const DirasstyTextField(
              label: 'Username',
              successText: '✓ Disponible',
            ),
            const PinBoxes(value: '12'),
            const PinBoxes(value: '482', length: 6, obscure: false),
            PinPad(onDigit: (_) {}, onBackspace: () {}),
          ],
        ),
        locale: locale,
        surface: const Size(393, 1100),
      );
      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/inputs_$lang.png'),
      );
    });

    testWidgets('progress ($lang)', (tester) async {
      await pumpDirassty(
        tester,
        const _Gallery(
          children: [
            JourneyBar(
              steps: ['Vidéo', 'Leçon', 'Exercices'],
              currentIndex: 1,
            ),
            Row(
              children: [
                MasteryRing(value: 0.72),
                SizedBox(width: 16),
                MasteryRing(value: 0.35, color: DirasstyColors.ink),
                SizedBox(width: 16),
                MasteryRing(value: 0.6, size: 80, stroke: 7),
              ],
            ),
            DirasstyProgressBar(value: 0.62),
            XpBar(value: 0.4),
            Row(
              children: [
                Expanded(
                  child: SubjectCard(
                    name: 'Mathématiques',
                    lessonsLabel: '24 leçons',
                    mastery: 0.72,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SubjectCard(
                    name: 'Physique',
                    lessonsLabel: '18 leçons',
                    mastery: 0.3,
                    ringColor: DirasstyColors.ink,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '86%',
                    label: 'Bonnes réponses',
                    emphasize: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    value: '5/7',
                    label: 'Jours actifs',
                    activeDays: [true, true, false, true, true, false, true],
                  ),
                ),
              ],
            ),
          ],
        ),
        locale: locale,
      );
      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/progress_$lang.png'),
      );
    });

    testWidgets('feedback ($lang)', (tester) async {
      await pumpDirassty(
        tester,
        _Gallery(
          padded: false,
          children: [
            OfflineBanner(onSee: () {}),
            FocusModeBar(untilLabel: '19:00', onUnlock: () {}),
            const EmptyState(
              icon: Icons.download_rounded,
              title: 'Aucun téléchargement',
              message: 'Télécharge une vidéo depuis une leçon.',
            ),
            ErrorState(onRetry: () {}),
            Builder(
              builder: (context) => DirasstyTabBar.student(
                context: context,
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
            Builder(
              builder: (context) => DirasstyTabBar.parent(
                context: context,
                currentIndex: 1,
                onTap: (_) {},
              ),
            ),
          ],
        ),
        locale: locale,
        surface: const Size(393, 1100),
      );
      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/feedback_$lang.png'),
      );
    });
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.children, this.padded = true});

  final List<Widget> children;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DirasstyColors.background,
      child: SingleChildScrollView(
        padding: padded ? const EdgeInsets.all(20) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final Widget child in children) ...[
              child,
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
