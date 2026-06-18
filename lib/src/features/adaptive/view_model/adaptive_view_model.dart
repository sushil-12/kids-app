import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';
import '../data/adaptive_repository.dart';
import '../data/difficulty.dart';

/// Injected persistence. Defaults to an in-memory store (so the engine works
/// without Hive in tests); `main()` overrides it with the Hive-backed store.
final adaptiveStoreProvider = Provider<AdaptiveStore>(
  (Ref ref) => EphemeralAdaptiveStore(),
);

/// Immutable view of the child's per-game skill estimates (0..1 each).
@immutable
class AdaptiveState {
  const AdaptiveState(this.skills);

  /// Skill estimate per game; absent means 0.0 (easiest).
  final Map<GameId, double> skills;

  /// The skill for [game], defaulting to 0.0.
  double skillFor(GameId game) => skills[game] ?? 0.0;

  /// Returns a new state with [game]'s skill replaced (immutable update).
  AdaptiveState withSkill(GameId game, double skill) =>
      AdaptiveState(<GameId, double>{...skills, game: skill});
}

/// Owns adaptive difficulty across every game. Loads each game's skill from the
/// [AdaptiveStore] on build and persists every change, so difficulty carries
/// across app restarts.
///
/// Games call:
///  - [difficultyFor] (a `ref.read`, point-in-time) when building a round, and
///  - [recordRound] when a round ends, to feed the heuristic.
///
/// It reads the child's [AgeBand] from the profile only to cap the youngest's
/// difficulty; the read is point-in-time and creates no rebuild dependency.
class AdaptiveViewModel extends Notifier<AdaptiveState> {
  static const DifficultyPolicy _policy = DifficultyPolicy();

  AdaptiveStore get _store => ref.read(adaptiveStoreProvider);

  @override
  AdaptiveState build() => AdaptiveState(<GameId, double>{
        for (final GameId game in GameId.values) game: _store.skillFor(game),
      });

  /// The difficulty to use for the next round of [game], given current skill
  /// and the child's age band.
  DifficultyLevel difficultyFor(GameId game) {
    final AgeBand band = ref.read(profileProvider)?.ageBand ?? AgeBand.junior;
    return _policy.levelFor(state.skillFor(game), band);
  }

  /// Records the outcome of one round of [game] and persists the updated skill.
  /// [struggled] is true when the child needed extra attempts that round; a
  /// clean round nudges difficulty up, a struggle gently eases it back.
  void recordRound(GameId game, {required bool struggled}) {
    final double next =
        _policy.updateSkill(state.skillFor(game), struggled: struggled);
    _store.saveSkill(game, next);
    state = state.withSkill(game, next);
  }
}

final adaptiveProvider =
    NotifierProvider<AdaptiveViewModel, AdaptiveState>(AdaptiveViewModel.new);
