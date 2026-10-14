/// Ported from `Difficulty` in packages/shared/src/types.
enum Difficulty {
  easy,
  medium,
  hard;

  String get dbValue => name;

  static Difficulty fromDb(String value) => switch (value) {
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => Difficulty.easy,
      };
}
