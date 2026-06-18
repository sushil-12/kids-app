import 'package:brightmind_kids/src/features/adaptive/data/adaptive_repository.dart';
import 'package:brightmind_kids/src/features/adaptive/data/difficulty.dart';
import 'package:brightmind_kids/src/features/adaptive/view_model/adaptive_view_model.dart';
import 'package:brightmind_kids/src/features/profile/data/child_profile.dart';
import 'package:brightmind_kids/src/features/profile/data/profile_repository.dart';
import 'package:brightmind_kids/src/features/profile/view_model/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [ProfileStore] returning a fixed profile (or none).
class FakeProfileStore implements ProfileStore {
  FakeProfileStore(this._profile);
  ChildProfile? _profile;

  @override
  ChildProfile? read() => _profile;

  @override
  void save(ChildProfile profile) => _profile = profile;

  @override
  void clear() => _profile = null;
}

ChildProfile _profileWith(AgeBand band) =>
    ChildProfile(name: 'Kid', ageBand: band, buddyId: '');

void main() {
  // The adaptive store persists across containers (stands in for Hive).
  late EphemeralAdaptiveStore store;
  late ProfileStore profileStore;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: <Override>[
          adaptiveStoreProvider.overrideWithValue(store),
          profileStoreProvider.overrideWithValue(profileStore),
        ],
      );

  setUp(() {
    store = EphemeralAdaptiveStore();
    profileStore = FakeProfileStore(_profileWith(AgeBand.senior));
  });

  test('a fresh child starts at the easiest difficulty', () {
    final ProviderContainer c = makeContainer();
    addTearDown(c.dispose);
    expect(
      c.read(adaptiveProvider.notifier).difficultyFor(GameId.countTap),
      DifficultyLevel.easy,
    );
  });

  test('clean rounds raise difficulty; the skill is per-game', () {
    final ProviderContainer c = makeContainer();
    addTearDown(c.dispose);
    final AdaptiveViewModel vm = c.read(adaptiveProvider.notifier);

    for (int i = 0; i < 4; i++) {
      vm.recordRound(GameId.countTap, struggled: false);
    }
    expect(vm.difficultyFor(GameId.countTap), DifficultyLevel.hard);
    // A different game is unaffected — skill is tracked independently.
    expect(vm.difficultyFor(GameId.oddOneOut), DifficultyLevel.easy);
  });

  test('a struggle eases difficulty back down', () {
    final ProviderContainer c = makeContainer();
    addTearDown(c.dispose);
    final AdaptiveViewModel vm = c.read(adaptiveProvider.notifier);

    for (int i = 0; i < 4; i++) {
      vm.recordRound(GameId.oddOneOut, struggled: false);
    }
    expect(vm.difficultyFor(GameId.oddOneOut), DifficultyLevel.hard);

    for (int i = 0; i < 3; i++) {
      vm.recordRound(GameId.oddOneOut, struggled: true);
    }
    expect(vm.difficultyFor(GameId.oddOneOut), isNot(DifficultyLevel.hard));
  });

  test('the youngest (junior) are capped at medium even at full skill', () {
    profileStore = FakeProfileStore(_profileWith(AgeBand.junior));
    final ProviderContainer c = makeContainer();
    addTearDown(c.dispose);
    final AdaptiveViewModel vm = c.read(adaptiveProvider.notifier);

    for (int i = 0; i < 10; i++) {
      vm.recordRound(GameId.countTap, struggled: false);
    }
    expect(vm.difficultyFor(GameId.countTap), DifficultyLevel.medium);
  });

  test('difficulty survives a restart (skill is persisted)', () {
    final ProviderContainer first = makeContainer();
    for (int i = 0; i < 4; i++) {
      first.read(adaptiveProvider.notifier).recordRound(GameId.countTap, struggled: false);
    }
    first.dispose();

    // Relaunch: a fresh container reading the same persisted store.
    final ProviderContainer second = makeContainer();
    addTearDown(second.dispose);
    expect(
      second.read(adaptiveProvider.notifier).difficultyFor(GameId.countTap),
      DifficultyLevel.hard,
    );
  });

  test('with no profile yet, it defaults to the junior cap', () {
    profileStore = FakeProfileStore(null);
    final ProviderContainer c = makeContainer();
    addTearDown(c.dispose);
    final AdaptiveViewModel vm = c.read(adaptiveProvider.notifier);

    for (int i = 0; i < 10; i++) {
      vm.recordRound(GameId.countTap, struggled: false);
    }
    expect(vm.difficultyFor(GameId.countTap), DifficultyLevel.medium);
  });
}
