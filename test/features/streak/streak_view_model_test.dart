import 'package:brightmind_kids/src/features/streak/data/streak_repository.dart';
import 'package:brightmind_kids/src/features/streak/view_model/streak_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [StreakStore] standing in for Hive. Persists across containers.
class FakeStreakStore implements StreakStore {
  int? _last;
  int _streak = 0;

  @override
  int? lastPlayedEpochDay() => _last;

  @override
  int currentStreak() => _streak;

  @override
  void save({required int lastPlayedEpochDay, required int streak}) {
    _last = lastPlayedEpochDay;
    _streak = streak;
  }
}

void main() {
  late FakeStreakStore store;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: <Override>[streakStoreProvider.overrideWithValue(store)],
      );

  StreakState read() => container.read(streakProvider);
  StreakViewModel vm() => container.read(streakProvider.notifier);

  setUp(() {
    store = FakeStreakStore();
    container = makeContainer();
  });
  tearDown(() => container.dispose());

  test('first ever visit starts the streak at 1', () {
    expect(read().streak, 0);
    vm().recordVisit(now: DateTime(2026, 6, 14));
    expect(read().streak, 1);
  });

  test('a second visit on the same day does not change the streak', () {
    vm().recordVisit(now: DateTime(2026, 6, 14, 9));
    vm().recordVisit(now: DateTime(2026, 6, 14, 20));
    expect(read().streak, 1);
  });

  test('visiting on consecutive days extends the streak', () {
    vm().recordVisit(now: DateTime(2026, 6, 14));
    vm().recordVisit(now: DateTime(2026, 6, 15));
    vm().recordVisit(now: DateTime(2026, 6, 16));
    expect(read().streak, 3);
  });

  test('a missed day resets the streak to 1', () {
    vm().recordVisit(now: DateTime(2026, 6, 14));
    vm().recordVisit(now: DateTime(2026, 6, 15));
    // Skip the 16th, return on the 17th.
    vm().recordVisit(now: DateTime(2026, 6, 17));
    expect(read().streak, 1);
  });

  test('the streak survives a restart and continues the next day', () {
    vm().recordVisit(now: DateTime(2026, 6, 14));
    vm().recordVisit(now: DateTime(2026, 6, 15));
    container.dispose();

    // Relaunch: fresh container reading the same persisted store.
    container = makeContainer();
    expect(read().streak, 2);
    vm().recordVisit(now: DateTime(2026, 6, 16));
    expect(read().streak, 3);
  });
}
