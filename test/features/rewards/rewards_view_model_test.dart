import 'package:brightmind_kids/src/features/rewards/data/reward_repository.dart';
import 'package:brightmind_kids/src/features/rewards/data/sticker_catalog.dart';
import 'package:brightmind_kids/src/features/rewards/view_model/rewards_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [RewardStore] standing in for Hive, so the view-model can be
/// tested without any platform setup. Persists across containers like a box.
class FakeRewardStore implements RewardStore {
  Set<String> _ids = <String>{};
  int _stars = 0;
  int _coins = 0;

  @override
  Set<String> earnedIds() => <String>{..._ids};

  @override
  void save(Set<String> ids) => _ids = <String>{...ids};

  @override
  int stars() => _stars;

  @override
  int coins() => _coins;

  @override
  void saveWallet({required int stars, required int coins}) {
    _stars = stars;
    _coins = coins;
  }
}

void main() {
  late FakeRewardStore store;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: <Override>[rewardStoreProvider.overrideWithValue(store)],
      );

  RewardsState read() => container.read(rewardsProvider);
  RewardsViewModel vm() => container.read(rewardsProvider.notifier);

  setUp(() {
    store = FakeRewardStore();
    container = makeContainer();
  });
  tearDown(() => container.dispose());

  test('awardRandom adds a new sticker and persists it', () {
    expect(read().earned, 0);

    final StickerAward award = vm().awardRandom();

    expect(award.isNew, isTrue);
    expect(read().earned, 1);
    expect(read().contains(award.sticker.id), isTrue);
    // Persisted to the store, not just held in memory.
    expect(store.earnedIds(), contains(award.sticker.id));
  });

  test('awardById awards the exact sticker, then reports repeats', () {
    final StickerAward first = vm().awardById('rocket');
    expect(first.sticker.id, 'rocket');
    expect(first.isNew, isTrue);

    final StickerAward again = vm().awardById('rocket');
    expect(again.sticker.id, 'rocket');
    expect(again.isNew, isFalse);
    expect(read().earned, 1, reason: 'a repeat must not inflate the count');
  });

  test('unknown ids fall back to a random award so a win is never dropped', () {
    final StickerAward award = vm().awardById('does-not-exist');
    expect(award.isNew, isTrue);
    expect(read().earned, 1);
  });

  test('collecting every sticker flips isComplete and stops adding', () {
    for (int i = 0; i < kStickers.length; i++) {
      vm().awardRandom();
    }
    expect(read().earned, kStickers.length);
    expect(read().isComplete, isTrue);

    // Past completion, wins still celebrate but the count cannot grow.
    final StickerAward extra = vm().awardRandom();
    expect(extra.isNew, isFalse);
    expect(read().earned, kStickers.length);
  });

  test('addWallet accumulates stars and coins and persists them', () {
    vm().addWallet(stars: 10, coins: 5);
    vm().addWallet(stars: 7, coins: 3);

    expect(read().stars, 17);
    expect(read().coins, 8);
    expect(store.stars(), 17);
    expect(store.coins(), 8);
  });

  test('addWallet ignores negative amounts — the wallet only grows', () {
    vm().addWallet(stars: 10, coins: 5);
    vm().addWallet(stars: -4, coins: -2);

    expect(read().stars, 10);
    expect(read().coins, 5);
  });

  test('wallet survives a restart (fresh container, same store)', () {
    vm().addWallet(stars: 12, coins: 6);
    container.dispose();

    container = makeContainer();
    expect(read().stars, 12);
    expect(read().coins, 6);
  });

  test('earning a sticker keeps the wallet intact', () {
    vm().addWallet(stars: 9, coins: 4);
    vm().awardById('lion');

    expect(read().stars, 9);
    expect(read().coins, 4);
    expect(read().contains('lion'), isTrue);
  });

  test('earned stickers survive a restart (fresh container, same store)', () {
    vm().awardById('lion');
    vm().awardById('star');
    container.dispose();

    // Simulate relaunch: new container reading the same persisted store.
    container = makeContainer();
    expect(read().earned, 2);
    expect(read().contains('lion'), isTrue);
    expect(read().contains('star'), isTrue);
  });
}
