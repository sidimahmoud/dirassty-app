import '../models/difficulty.dart';

/// Ported from `XPSource` in packages/shared/src/types, plus `exam` —
/// added in 033_exam_settings_and_xp.sql so a weekly exam's XP is
/// distinguishable from day-to-day lesson practice in a student's XP
/// history instead of blending into `exercise`.
enum XpSource {
  exercise,
  streak,
  badge,
  video,
  skill,
  challenge,
  exam;

  String get dbValue => name;
}

/// XP reward table and level system, ported 1:1 from
/// packages/shared/src/lib/gamification.ts — keep both in sync, this is
/// the same points economy the web app uses (a student's XP total must
/// mean the same thing on both clients).
abstract final class XpRewards {
  static const int correctEasy = 5;
  static const int correctMedium = 10;
  static const int correctHard = 20;
  static const int perfectSessionBonus = 25;
  static const int dailyStreak = 15;
  static const int videoWatched = 10;
  static const int skillMission = 50;
  static const int badgeEarned = 30;

  /// Flat bonus for finishing a weekly exam, on top of the same
  /// per-correct-answer rewards regular practice earns — awarded
  /// regardless of score, since showing up to a longer cumulative-review
  /// exam is itself worth reinforcing.
  static const int examCompletionBonus = 20;
}

int xpForCorrectAnswer(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => XpRewards.correctEasy,
      Difficulty.medium => XpRewards.correctMedium,
      Difficulty.hard => XpRewards.correctHard,
    };

const List<int> _levelThresholds = [
  0,
  100,
  250,
  500,
  1000,
  2000,
  3500,
  5000,
  7500,
  10000,
];

int levelFromXp(int xpTotal) {
  for (int i = _levelThresholds.length - 1; i >= 0; i--) {
    if (xpTotal >= _levelThresholds[i]) return i + 1;
  }
  return 1;
}

/// XP at which the level after [xpTotal]'s current one starts — the
/// "/ 1 500 XP" on the home level card. At the top level it's the last
/// threshold (progress then reads as full).
int nextLevelXp(int xpTotal) {
  final int level = levelFromXp(xpTotal);
  return level < _levelThresholds.length
      ? _levelThresholds[level]
      : _levelThresholds.last;
}

/// Progress (0–1) within the student's current level, for a level-up
/// progress bar.
double levelProgress(int xpTotal) {
  final int level = levelFromXp(xpTotal);
  final int currentThreshold =
      level - 1 < _levelThresholds.length ? _levelThresholds[level - 1] : 0;
  final int nextThreshold = level < _levelThresholds.length
      ? _levelThresholds[level]
      : _levelThresholds.last;
  if (nextThreshold == currentThreshold) return 1;
  return (xpTotal - currentThreshold) / (nextThreshold - currentThreshold);
}

Difficulty difficultyFromMastery(double mastery) {
  if (mastery < 0.4) return Difficulty.easy;
  if (mastery < 0.7) return Difficulty.medium;
  return Difficulty.hard;
}

/// One answer in a finished QCM session, for [calculateSessionXp].
class SessionAnswer {
  const SessionAnswer({required this.correct, required this.difficulty});

  final bool correct;
  final Difficulty difficulty;
}

/// Total XP for a finished session — per-correct-answer rewards plus a
/// flat bonus for a perfect run of 5+ questions. Ported from
/// `calculateSessionXP` in packages/shared/src/lib/gamification.ts.
int calculateSessionXp(List<SessionAnswer> answers) {
  int total = 0;
  int correctCount = 0;
  for (final SessionAnswer answer in answers) {
    if (!answer.correct) continue;
    correctCount++;
    total += xpForCorrectAnswer(answer.difficulty);
  }
  if (correctCount == answers.length && answers.length >= 5) {
    total += XpRewards.perfectSessionBonus;
  }
  return total;
}

/// The streak increment/reset rule for a new day's activity — pure and
/// unit-tested (see test/core/gamification/gamification_test.dart)
/// independently of Supabase. Only called once the caller already knows
/// today hasn't been counted yet (see ProgressRepository.updateStreak).
/// Same 3-day grace window as supabase/functions/check-streaks, which
/// zeroes out a stale streak on the same cutoff for a student who never
/// comes back at all: missing 1 or 2 days in a row doesn't break the
/// streak, only a 3rd consecutive missed day does. [lastDate] is a
/// 'YYYY-MM-DD' string (or null for a student with no streak yet).
int nextStreak({
  required int currentStreak,
  required String? lastDate,
  required DateTime now,
}) {
  final String graceCutoff =
      now.subtract(const Duration(days: 3)).toIso8601String().split('T').first;
  return (lastDate != null && lastDate.compareTo(graceCutoff) >= 0)
      ? currentStreak + 1
      : 1;
}
