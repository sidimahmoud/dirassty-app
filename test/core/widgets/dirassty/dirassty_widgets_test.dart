import 'package:dirassty/core/theme/dirassty_theme.dart';
import 'package:dirassty/core/widgets/dirassty/dirassty_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/dirassty_harness.dart';

void main() {
  group('DirasstyButton', () {
    testWidgets('calls onPressed and is 52 high', (tester) async {
      int taps = 0;
      await pumpDirassty(
        tester,
        DirasstyButton(label: 'Continuer', onPressed: () => taps++),
      );
      await tester.tap(find.text('Continuer'));
      expect(taps, 1);
      expect(
        tester.getSize(find.byType(DirasstyButton)).height,
        DirasstySize.button,
      );
    });

    testWidgets('disabled button ignores taps', (tester) async {
      await pumpDirassty(
        tester,
        const DirasstyButton(label: 'Continuer', onPressed: null),
      );
      await tester.tap(find.text('Continuer'), warnIfMissed: false);
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    });

    testWidgets('loading shows a spinner instead of the label and ignores taps',
        (tester) async {
      int taps = 0;
      await pumpDirassty(
        tester,
        DirasstyButton(
          label: 'Continuer',
          loading: true,
          onPressed: () => taps++,
        ),
        settle: false,
      );
      expect(find.text('Continuer'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(DirasstyButton));
      expect(taps, 0);
    });
  });

  group('PinPad', () {
    for (final Locale locale in [fr, ar]) {
      testWidgets(
          'emits digits and backspace, and keeps 1-2-3 left to right (${locale.languageCode})',
          (tester) async {
        final List<String> digits = [];
        int backspaces = 0;
        await pumpDirassty(
          tester,
          PinPad(onDigit: digits.add, onBackspace: () => backspaces++),
          locale: locale,
        );
        await tester.tap(find.text('7'));
        await tester.tap(find.text('0'));
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        expect(digits, ['7', '0']);
        expect(backspaces, 1);
        expect(
          tester.getCenter(find.text('1')).dx,
          lessThan(tester.getCenter(find.text('3')).dx),
        );
      });
    }
  });

  testWidgets('PinBoxes shows one dot per entered digit', (tester) async {
    await pumpDirassty(
      tester,
      const Padding(
        padding: EdgeInsets.all(20),
        child: PinBoxes(value: '12'),
      ),
    );
    final Iterable<Container> dots =
        tester.widgetList<Container>(find.byType(Container)).where(
              (c) =>
                  (c.decoration is BoxDecoration) &&
                  (c.decoration! as BoxDecoration).shape == BoxShape.circle,
            );
    expect(dots.length, 2);
  });

  testWidgets('MasteryRing shows the rounded percentage', (tester) async {
    await pumpDirassty(tester, const Center(child: MasteryRing(value: 0.426)));
    expect(find.text('43%'), findsOneWidget);
  });

  testWidgets('tappable DirasstyChip keeps a 44 pt touch target',
      (tester) async {
    await pumpDirassty(
      tester,
      Center(child: DirasstyChip(label: 'Toutes', onTap: () {})),
    );
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(DirasstySize.minTouch),
    );
  });

  testWidgets('JourneyBar mirrors in Arabic', (tester) async {
    const Widget bar = Padding(
      padding: EdgeInsets.all(20),
      child: JourneyBar(steps: ['A', 'B', 'C'], currentIndex: 1),
    );
    await pumpDirassty(tester, bar);
    final double frFirst = tester.getCenter(find.text('A')).dx;
    final double frLast = tester.getCenter(find.text('C')).dx;
    expect(frFirst, lessThan(frLast));

    await pumpDirassty(tester, bar, locale: ar);
    expect(
      tester.getCenter(find.text('A')).dx,
      greaterThan(tester.getCenter(find.text('C')).dx),
    );
  });

  group('localized components', () {
    testWidgets('ErrorState uses the locale copy and retries', (tester) async {
      int retries = 0;
      await pumpDirassty(
        tester,
        Center(child: ErrorState(onRetry: () => retries++)),
      );
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);

      await pumpDirassty(
        tester,
        Center(child: ErrorState(onRetry: () {})),
        locale: ar,
      );
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('OfflineBanner shows the offline copy', (tester) async {
      await pumpDirassty(tester, OfflineBanner(onSee: () {}));
      expect(find.textContaining('Hors ligne'), findsOneWidget);
      expect(find.text('Voir'), findsOneWidget);
    });

    testWidgets('FocusModeBar shows the end time and unlocks', (tester) async {
      int unlocks = 0;
      await pumpDirassty(
        tester,
        FocusModeBar(untilLabel: '19:00', onUnlock: () => unlocks++),
      );
      expect(find.textContaining('19:00'), findsOneWidget);
      await tester.tap(find.text('Déverrouiller'));
      expect(unlocks, 1);
    });
  });

  group('DirasstyTabBar', () {
    testWidgets('student has 4 tabs, parent has 3, taps report the index',
        (tester) async {
      int? tapped;
      await pumpDirassty(
        tester,
        Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: DirasstyTabBar.student(
              context: context,
              currentIndex: 0,
              onTap: (i) => tapped = i,
            ),
          ),
        ),
      );
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      await tester.tap(find.text('Examens'));
      expect(tapped, 2);

      await pumpDirassty(
        tester,
        Builder(
          builder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: DirasstyTabBar.parent(
              context: context,
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Examens'), findsNothing);
    });
  });

  testWidgets('showDirasstyDialog returns the tapped action value',
      (tester) async {
    String? result;
    await pumpDirassty(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              result = await showDirasstyDialog<String>(
                context,
                title: 'Quitter la session ?',
                actions: const [
                  DirasstyDialogAction(
                    label: 'Quitter',
                    value: 'leave',
                    variant: DirasstyButtonVariant.danger,
                  ),
                  DirasstyDialogAction(
                    label: 'Rester',
                    value: 'stay',
                    variant: DirasstyButtonVariant.quiet,
                  ),
                ],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(result, 'stay');
  });
}
