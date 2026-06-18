import 'package:hive_ce_flutter/hive_flutter.dart';

import 'difficulty.dart';

/// Persistence boundary for per-game skill estimates. Behind an interface so the
/// view-model can be unit-tested with an in-memory store, with no Hive setup.
///
/// Skill is a 0..1 estimate maintained by [DifficultyPolicy]; the store only
/// reads and writes it.
abstract interface class AdaptiveStore {
  /// The saved skill for [game], or 0.0 (easiest) if never recorded.
  double skillFor(GameId game);

  /// Persists the updated skill for [game].
  void saveSkill(GameId game, double skill);
}

/// In-memory [AdaptiveStore]. The default binding: adaptive skill has a sensible
/// code default (0.0 → easiest) and must never block the app or a test that
/// hasn't wired Hive. `main()` swaps in the Hive-backed store for persistence.
class EphemeralAdaptiveStore implements AdaptiveStore {
  final Map<GameId, double> _skills = <GameId, double>{};

  @override
  double skillFor(GameId game) => _skills[game] ?? 0.0;

  @override
  void saveSkill(GameId game, double skill) => _skills[game] = skill;
}

/// Hive-backed [AdaptiveStore]. The box is opened once at app start (see
/// `main.dart`). Keyed by [GameId.token].
///
/// This is on-device only — it holds no identity, just per-game skill, and
/// never leaves the device (COPPA/DPDP: child data stays local).
class HiveAdaptiveStore implements AdaptiveStore {
  HiveAdaptiveStore(this._box);

  /// Name of the Hive box that holds adaptive skill estimates.
  static const String boxName = 'adaptive';

  final Box<dynamic> _box;

  @override
  double skillFor(GameId game) {
    final dynamic v = _box.get(game.token);
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return 0.0;
  }

  @override
  void saveSkill(GameId game, double skill) => _box.put(game.token, skill);
}
