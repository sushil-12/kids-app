import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reward_repository.dart';
import '../data/sticker.dart';
import '../data/sticker_catalog.dart';

/// Injected persistence. Overridden in `main()` with the Hive-backed store once
/// its box is open; overridden again with an in-memory fake in tests.
final rewardStoreProvider = Provider<RewardStore>(
  (Ref ref) => throw UnimplementedError(
    'rewardStoreProvider must be overridden in main() with a RewardStore',
  ),
);

/// Result of awarding a sticker — what to show, and whether it was newly earned
/// (vs. the collection already being complete).
@immutable
class StickerAward {
  const StickerAward({required this.sticker, required this.isNew});

  final Sticker sticker;
  final bool isNew;
}

/// Immutable view of the child's sticker collection + story-reward wallet.
@immutable
class RewardsState {
  const RewardsState(this.earnedIds, {this.stars = 0, this.coins = 0});

  /// Ids of every earned sticker.
  final Set<String> earnedIds;

  /// Stars and coins earned from cinematic story rewards.
  final int stars;
  final int coins;

  int get earned => earnedIds.length;
  int get total => kStickers.length;
  bool get isComplete => earned >= total;

  bool contains(String id) => earnedIds.contains(id);
}

/// Owns the sticker collection. Loads earned ids from the [RewardStore] on
/// build and persists every change, so progress survives app restarts.
class RewardsViewModel extends Notifier<RewardsState> {
  final math.Random _rng = math.Random();

  RewardStore get _store => ref.read(rewardStoreProvider);

  @override
  RewardsState build() => RewardsState(
        _store.earnedIds(),
        stars: _store.stars(),
        coins: _store.coins(),
      );

  /// Awards a random not-yet-earned sticker and persists it. If everything is
  /// already collected, returns a celebratory repeat without changing state —
  /// the child still always wins (House Rule §5).
  StickerAward awardRandom() {
    final List<Sticker> remaining = kStickers
        .where((Sticker s) => !state.earnedIds.contains(s.id))
        .toList(growable: false);

    if (remaining.isEmpty) {
      return StickerAward(
        sticker: kStickers[_rng.nextInt(kStickers.length)],
        isNew: false,
      );
    }

    final Sticker awarded = remaining[_rng.nextInt(remaining.length)];
    _earn(awarded.id);
    return StickerAward(sticker: awarded, isNew: true);
  }

  /// Awards a specific sticker by id (e.g. a coloring page's authored reward).
  /// Falls back to a random sticker if the id is unknown, so a win is never
  /// silently dropped.
  StickerAward awardById(String id) {
    final Sticker? target = stickerById(id);
    if (target == null) return awardRandom();
    final bool isNew = !state.earnedIds.contains(id);
    if (isNew) _earn(id);
    return StickerAward(sticker: target, isNew: isNew);
  }

  /// Adds a story reward to the wallet and persists it. Negative amounts are
  /// ignored — the wallet only ever grows (House Rule §5: every finish wins).
  void addWallet({int stars = 0, int coins = 0}) {
    final int nextStars = state.stars + math.max(0, stars);
    final int nextCoins = state.coins + math.max(0, coins);
    _store.saveWallet(stars: nextStars, coins: nextCoins);
    state = RewardsState(state.earnedIds, stars: nextStars, coins: nextCoins);
  }

  void _earn(String id) {
    final Set<String> next = <String>{...state.earnedIds, id};
    _store.save(next);
    state = RewardsState(next, stars: state.stars, coins: state.coins);
  }
}

final rewardsProvider =
    NotifierProvider<RewardsViewModel, RewardsState>(RewardsViewModel.new);
