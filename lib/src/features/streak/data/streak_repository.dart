import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persistence boundary for the daily-play streak. Behind an interface so the
/// view-model can be unit-tested with an in-memory store, with no Hive setup.
abstract interface class StreakStore {
  /// The day (days-since-epoch) the child last opened the app, or null if never.
  int? lastPlayedEpochDay();

  /// The current consecutive-day streak (0 if never played).
  int currentStreak();

  /// Persists a visit: the day it happened and the resulting streak length.
  void save({required int lastPlayedEpochDay, required int streak});
}

/// Hive-backed [StreakStore]. The box is opened once at app start (see
/// `main.dart`).
class HiveStreakStore implements StreakStore {
  HiveStreakStore(this._box);

  /// Name of the Hive box that holds streak progress.
  static const String boxName = 'streak';
  static const String _lastKey = 'lastPlayedEpochDay';
  static const String _streakKey = 'currentStreak';

  final Box<dynamic> _box;

  @override
  int? lastPlayedEpochDay() {
    final dynamic v = _box.get(_lastKey);
    return v is int ? v : null;
  }

  @override
  int currentStreak() {
    final dynamic v = _box.get(_streakKey);
    return v is int ? v : 0;
  }

  @override
  void save({required int lastPlayedEpochDay, required int streak}) {
    _box
      ..put(_lastKey, lastPlayedEpochDay)
      ..put(_streakKey, streak);
  }
}
