import 'package:intl/intl.dart';

/// Locale-aware dates that always use Western digits (0–9), in French
/// and Arabic alike (DESIGN_SPEC §7 "Numbers").
///
/// intl's Arabic formats default to Arabic-Indic digits; [ensureWesternDigits]
/// turns that off once, at startup (called from bootstrap). Month/day
/// names still follow the locale.
abstract final class DirasstyDates {
  static bool _configured = false;

  static void ensureWesternDigits() {
    if (_configured) return;
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    _configured = true;
  }

  static String _tag(String languageCode) => languageCode == 'ar' ? 'ar' : 'fr';

  /// "jeudi" / "الخميس".
  static String weekday(DateTime date, String languageCode) {
    ensureWesternDigits();
    return DateFormat.EEEE(_tag(languageCode)).format(date);
  }

  /// "samedi · 10:00" / "السبت · 10:00".
  static String weekdayTime(DateTime date, String languageCode) {
    ensureWesternDigits();
    final String tag = _tag(languageCode);
    return '${DateFormat.EEEE(tag).format(date)} · ${DateFormat.Hm(tag).format(date)}';
  }

  /// "22 – 28 sept." (same month) or "30 sept. – 6 oct.".
  static String dayMonthRange(
    DateTime start,
    DateTime end,
    String languageCode,
  ) {
    ensureWesternDigits();
    final String tag = _tag(languageCode);
    if (start.month == end.month) {
      return '${start.day} – ${DateFormat('d MMM', tag).format(end)}';
    }
    return '${DateFormat('d MMM', tag).format(start)} – ${DateFormat('d MMM', tag).format(end)}';
  }

  /// "12 oct. 2026".
  static String dayMonthYear(DateTime date, String languageCode) {
    ensureWesternDigits();
    return DateFormat('d MMM y', _tag(languageCode)).format(date);
  }

  /// Whole calendar days from today to [date] (0 = today, negative = past).
  static int daysFromToday(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.difference(today).inDays;
  }
}
