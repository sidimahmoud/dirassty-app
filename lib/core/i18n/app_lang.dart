import 'package:flutter/widgets.dart';

/// The two languages Dirassty ships today — both the UI chrome language
/// (each pre-login auth screen still holds its own [AppLang] as local,
/// ephemeral state, mirroring the web login page; once logged in, the
/// app-wide choice lives in [appLanguageProvider] instead, persisted via
/// `shared_preferences` and changeable from the Profile screen) and the
/// `'fr' | 'ar'` tag Postgres stores on subjects/lessons/content
/// (`Language`/`SubjectLang` in packages/shared/src/types). One enum for
/// both since they're the same two-value domain — a subject's content
/// language and the app's display language are the same kind of thing,
/// just set independently.
enum AppLang {
  fr,
  ar;

  bool get isArabic => this == AppLang.ar;

  Locale get flutterLocale => switch (this) {
        AppLang.fr => const Locale('fr'),
        AppLang.ar => const Locale('ar'),
      };

  String get dbValue => switch (this) {
        AppLang.fr => 'fr',
        AppLang.ar => 'ar',
      };

  static AppLang fromDb(String value) => switch (value) {
        'ar' => AppLang.ar,
        _ => AppLang.fr,
      };
}
