import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dirassty/core/theme/dirassty_theme.dart';
import 'package:dirassty/l10n/app_localizations.dart';

const Locale fr = Locale('fr');
const Locale ar = Locale('ar');

/// Pumps [child] inside the real app theme and localizations for
/// [locale] — the same setup MaterialApp gets in DirasstyApp.
Future<void> pumpDirassty(
  WidgetTester tester,
  Widget child, {
  Locale locale = fr,
  Size surface = const Size(393, 852),
  // False for anything that animates forever (Skeleton shimmer), where
  // pumpAndSettle would never return.
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DirasstyTheme.light(locale),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  settle
      ? await tester.pumpAndSettle()
      : await tester.pump(const Duration(milliseconds: 500));
}
