import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lang.dart';

const String _prefsKey = 'app_language';

/// The app-wide display language once logged in, persisted across
/// launches via `shared_preferences`. Starts as French (matching the web
/// app's default) and hydrates asynchronously right after — screens
/// don't wait on that; a one-frame flash of the default before the saved
/// choice loads is an acceptable trade for not blocking app startup on
/// disk I/O. [DirasstyApp] watches this for `MaterialApp.locale`; the
/// Profile screen is the only place that calls [setLanguage].
class AppLanguageNotifier extends Notifier<AppLang> {
  @override
  AppLang build() {
    _hydrate();
    return AppLang.fr;
  }

  Future<void> _hydrate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey);
    if (stored != null) {
      state = AppLang.fromDb(stored);
    }
  }

  Future<void> setLanguage(AppLang lang) async {
    state = lang;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, lang.dbValue);
  }
}

final NotifierProvider<AppLanguageNotifier, AppLang> appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLang>(AppLanguageNotifier.new);
