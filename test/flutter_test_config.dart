import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file: registers the bundled Inter and Cairo
/// fonts so widget and golden tests render real glyphs (Arabic joining
/// included) instead of the test framework's placeholder boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final String family in ['Inter', 'Cairo']) {
    final FontLoader loader = FontLoader(family);
    for (final String weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
    }
    await loader.load();
  }
  await testMain();
}
