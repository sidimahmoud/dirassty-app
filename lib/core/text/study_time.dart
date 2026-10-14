import '../../l10n/app_localizations.dart';

/// "45 min" under an hour, "5 h 10" from there on — how study time is
/// shown everywhere on the parent side (DESIGN_SPEC ParentHome).
String formatStudyTime(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.minutesShort(minutes);
  return l10n.hoursMinutes(
      minutes ~/ 60, (minutes % 60).toString().padLeft(2, '0'));
}
