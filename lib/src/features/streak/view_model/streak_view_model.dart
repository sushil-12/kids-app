import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/streak_repository.dart';

/// Injected persistence. Overridden in `main()` with the Hive-backed store once
/// its box is open; overridden again with an in-memory fake in tests.
final streakStoreProvider = Provider<StreakStore>(
  (Ref ref) => throw UnimplementedError(
    'streakStoreProvider must be overridden in main() with a StreakStore',
  ),
);

/// Immutable view of the daily-play streak.
@immutable
class StreakState {
  const StreakState({required this.streak, this.lastPlayedEpochDay});

  /// Consecutive days played, including today once a visit is recorded.
  final int streak;

  /// The day (days-since-epoch) of the most recent visit, or null if never.
  final int? lastPlayedEpochDay;

  StreakState copyWith({int? streak, int? lastPlayedEpochDay}) => StreakState(
        streak: streak ?? this.streak,
        lastPlayedEpochDay: lastPlayedEpochDay ?? this.lastPlayedEpochDay,
      );
}

/// Owns the daily-play streak. Loads from the [StreakStore] on build, and
/// [recordVisit] is called once when the home screen appears: a same-day reopen
/// is a no-op, a next-day visit extends the streak, and a longer gap restarts
/// it at 1. There is no penalty beyond resetting — it stays encouraging.
class StreakViewModel extends Notifier<StreakState> {
  StreakStore get _store => ref.read(streakStoreProvider);

  @override
  StreakState build() => StreakState(
        streak: _store.currentStreak(),
        lastPlayedEpochDay: _store.lastPlayedEpochDay(),
      );

  /// Records that the child opened the app. [now] is injectable for tests.
  void recordVisit({DateTime? now}) {
    final int today = _epochDay(now ?? DateTime.now());
    final int? last = state.lastPlayedEpochDay;

    if (last == today) return; // already counted today

    final int streak =
        (last != null && last == today - 1) ? state.streak + 1 : 1;
    _store.save(lastPlayedEpochDay: today, streak: streak);
    state = StreakState(streak: streak, lastPlayedEpochDay: today);
  }

  /// Whole days since the Unix epoch for the *local* calendar date, so a streak
  /// turns over at local midnight rather than UTC.
  static int _epochDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

final streakProvider =
    NotifierProvider<StreakViewModel, StreakState>(StreakViewModel.new);
