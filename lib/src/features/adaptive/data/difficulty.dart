import '../../profile/data/child_profile.dart';

/// The games whose difficulty can adapt. The [token] is the persistence key —
/// never rename. Not every game is wired yet; ids exist so the engine and store
/// are ready as each game opts in.
enum GameId {
  countTap,
  oddOneOut,
  shapeSorter,
  colorMatch,
  memoryFlip,
  letterTrace,
  pattern;

  /// Stable token persisted in Hive.
  String get token => name;
}

/// How hard the next round should be. Games map this onto their own knobs
/// (how many items, how subtle the difference, etc.).
enum DifficultyLevel { easy, medium, hard }

/// The adaptive policy — a small, transparent heuristic (no ML infra, per
/// `claude-ai.md` §2A.6 "heuristic first"). It maintains a 0..1 skill estimate
/// per game that drifts up on clean rounds and gently down on a struggle, then
/// maps that estimate to a [DifficultyLevel], capped by age band.
///
/// Pure and dependency-light so it is trivially unit-testable.
class DifficultyPolicy {
  const DifficultyPolicy();

  /// Skill gained after a clean round. Larger than [struggleStep] so sustained
  /// success ramps difficulty, but a child still reaches "hard" only after
  /// several wins.
  static const double cleanStep = 0.18;

  /// Skill lost after a round where the child struggled. Deliberately gentle —
  /// difficulty eases back without ever feeling like a punishment (House §5).
  static const double struggleStep = 0.12;

  /// Skill below this is [DifficultyLevel.easy]; below [_hardThreshold] is
  /// medium; at or above it is hard.
  static const double _mediumThreshold = 0.34;
  static const double _hardThreshold = 0.67;

  /// Updates a 0..1 skill estimate after a round, clamped to the unit range.
  double updateSkill(double skill, {required bool struggled}) {
    final double delta = struggled ? -struggleStep : cleanStep;
    return (skill + delta).clamp(0.0, 1.0);
  }

  /// Maps a skill estimate to a difficulty, capped by [band] so the youngest
  /// (2–4) never get the hardest rounds — they stay encouraging by design.
  DifficultyLevel levelFor(double skill, AgeBand band) {
    final DifficultyLevel raw = skill < _mediumThreshold
        ? DifficultyLevel.easy
        : skill < _hardThreshold
            ? DifficultyLevel.medium
            : DifficultyLevel.hard;

    if (band == AgeBand.junior && raw == DifficultyLevel.hard) {
      return DifficultyLevel.medium;
    }
    return raw;
  }
}
