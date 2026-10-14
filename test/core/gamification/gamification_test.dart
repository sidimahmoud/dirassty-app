import 'package:flutter_test/flutter_test.dart';
import 'package:dirassty/core/gamification/gamification.dart';
import 'package:dirassty/core/models/difficulty.dart';

void main() {
  group('xpForCorrectAnswer', () {
    test('rewards scale with difficulty', () {
      expect(xpForCorrectAnswer(Difficulty.easy), 5);
      expect(xpForCorrectAnswer(Difficulty.medium), 10);
      expect(xpForCorrectAnswer(Difficulty.hard), 20);
    });
  });

  group('levelFromXp', () {
    test('starts at level 1 below the first threshold', () {
      expect(levelFromXp(0), 1);
      expect(levelFromXp(99), 1);
    });

    test('advances exactly at each threshold', () {
      expect(levelFromXp(100), 2);
      expect(levelFromXp(250), 3);
      expect(levelFromXp(10000), 10);
    });

    test('caps at the top level past the last threshold', () {
      expect(levelFromXp(999999), 10);
    });
  });

  group('calculateSessionXp', () {
    test('sums only correct answers', () {
      final xp = calculateSessionXp([
        const SessionAnswer(correct: true, difficulty: Difficulty.easy),
        const SessionAnswer(correct: false, difficulty: Difficulty.hard),
        const SessionAnswer(correct: true, difficulty: Difficulty.medium),
      ]);
      expect(xp, 5 + 10);
    });

    test('adds the perfect-session bonus for 5+ all-correct answers', () {
      final answers = List.generate(
        5,
        (_) => const SessionAnswer(correct: true, difficulty: Difficulty.easy),
      );
      expect(
          calculateSessionXp(answers), 5 * 5 + XpRewards.perfectSessionBonus);
    });

    test('withholds the bonus if any answer is wrong, even at 5+', () {
      final answers = [
        ...List.generate(
            4,
            (_) => const SessionAnswer(
                correct: true, difficulty: Difficulty.easy)),
        const SessionAnswer(correct: false, difficulty: Difficulty.easy),
      ];
      expect(calculateSessionXp(answers), 5 * 4);
    });

    test('withholds the bonus for an all-correct run under 5 questions', () {
      final answers = List.generate(
        3,
        (_) => const SessionAnswer(correct: true, difficulty: Difficulty.easy),
      );
      expect(calculateSessionXp(answers), 5 * 3);
    });
  });

  group('nextStreak', () {
    final now = DateTime(2026, 1, 10);

    test('increments when last active yesterday', () {
      expect(
        nextStreak(currentStreak: 4, lastDate: '2026-01-09', now: now),
        5,
      );
    });

    test('increments within the 3-day grace window (2 missed days)', () {
      expect(
        nextStreak(currentStreak: 4, lastDate: '2026-01-07', now: now),
        5,
      );
    });

    test('resets to 1 once the grace window is exceeded (3+ missed days)', () {
      expect(
        nextStreak(currentStreak: 4, lastDate: '2026-01-06', now: now),
        1,
      );
    });

    test('resets to 1 for a student with no prior streak', () {
      expect(nextStreak(currentStreak: 0, lastDate: null, now: now), 1);
    });
  });
}
