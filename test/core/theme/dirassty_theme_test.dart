import 'package:dirassty/core/theme/dirassty_theme.dart';
import 'package:dirassty/core/theme/subject_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DirasstyTheme.light', () {
    // Fonts are bundled assets now (no google_fonts network fetch), so
    // the theme builds offline and these no longer need to be skipped.
    test('uses the brand teal as primary', () {
      expect(
        DirasstyTheme.light(const Locale('fr')).colorScheme.primary,
        DirasstyColors.teal,
      );
    });

    test('sets the scaffold background to the brand background token', () {
      expect(
        DirasstyTheme.light(const Locale('fr')).scaffoldBackgroundColor,
        DirasstyColors.background,
      );
    });

    test('uses Cairo for Arabic and Inter for French', () {
      expect(
        DirasstyTheme.light(const Locale('ar')).textTheme.bodyLarge?.fontFamily,
        'Cairo',
      );
      expect(
        DirasstyTheme.light(const Locale('fr')).textTheme.bodyLarge?.fontFamily,
        'Inter',
      );
    });
  });

  group('kSubjectMeta', () {
    test('has an entry for every SubjectKey value', () {
      expect(kSubjectMeta.keys.toSet(), SubjectKey.values.toSet());
    });

    test('marks arabe and islam — and only those — as RTL', () {
      final rtlSubjects = kSubjectMeta.entries
          .where((e) => e.value.isRtl)
          .map((e) => e.key)
          .toSet();
      expect(rtlSubjects, {SubjectKey.arabe, SubjectKey.islam});
    });
  });
}
