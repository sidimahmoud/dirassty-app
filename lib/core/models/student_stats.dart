import 'package:flutter/foundation.dart';

/// Stats for one fixed rolling window (7 or 30 days) — computed once by
/// [ProgressRepository.getStudentStats] and reused for both the "Semaine"
/// and "Mois" views of the stats grid, so there's only ever one
/// definition of "days active"/"exercises done"/"% correct"/"minutes on
/// app" per period.
@immutable
class PeriodStats {
  const PeriodStats({
    required this.periodDays,
    required this.exercisesDone,
    required this.correctRate,
    required this.daysActive,
    required this.minutesOnApp,
  });

  static const PeriodStats empty = PeriodStats(
    periodDays: 0,
    exercisesDone: 0,
    correctRate: 0,
    daysActive: 0,
    minutesOnApp: 0,
  );

  /// 7 for the week window, 30 for the month window.
  final int periodDays;
  final int exercisesDone;

  /// 0–1.
  final double correctRate;
  final int daysActive;
  final int minutesOnApp;
}

/// A student's current streak (not period-scoped — a single running
/// count, reset by supabase/functions/check-streaks) plus their week and
/// month [PeriodStats].
@immutable
class StudentStats {
  const StudentStats({
    required this.streak,
    required this.week,
    required this.month,
    this.last7DaysMinutes = const [],
  });

  static const StudentStats empty = StudentStats(
    streak: 0,
    week: PeriodStats.empty,
    month: PeriodStats.empty,
  );

  final int streak;
  final PeriodStats week;
  final PeriodStats month;

  /// Minutes studied per local calendar day, oldest first, today last
  /// (7 entries) — the parent home's activity bars. Derived from the same
  /// `study_sessions` rows as [week], so it costs no extra query.
  final List<int> last7DaysMinutes;
}
