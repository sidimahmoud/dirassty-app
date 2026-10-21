import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/monitoring/error_reporting.dart';
import '../core/push/push_service.dart';
import '../core/text/dirassty_dates.dart';
import 'app.dart';

/// Single entry point for wiring cross-cutting concerns — error handling,
/// crash reporting, Supabase, the Riverpod container — before the widget
/// tree starts. Keeping this separate from `main.dart` means `main.dart`
/// never grows past one line as more of those concerns get added later
/// (e.g. Firebase, Sentry — see ErrorReporting).
Future<void> bootstrap() async {
  // Keep the native launch screen up until SplashOverlay has its logo
  // decoded and takes over (it calls FlutterNativeSplash.remove()).
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  // Western digits in Arabic dates too (DESIGN_SPEC §7).
  DirasstyDates.ensureWesternDigits();

  // Console output in debug; ErrorReporting (Sentry) chains onto this
  // and also reports the error when a DSN is configured.
  FlutterError.onError = FlutterError.presentError;

  // Push: Firebase + background message handler, before runApp.
  await PushService.setUpBackgroundHandling();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  await ErrorReporting.start(const ProviderScope(child: DirasstyApp()));
}
