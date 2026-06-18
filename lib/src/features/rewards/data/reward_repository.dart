import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persistence boundary for earned stickers. Kept behind an interface so the
/// view-model can be unit-tested with an in-memory store, with no Hive setup.
abstract interface class RewardStore {
  /// The ids of every sticker the child has earned so far.
  Set<String> earnedIds();

  /// Replaces the persisted set of earned sticker ids.
  void save(Set<String> ids);
}

/// Hive-backed [RewardStore]. The box is opened once at app start (see
/// `main.dart`) and stores the earned ids as a simple `List<String>`.
class HiveRewardStore implements RewardStore {
  HiveRewardStore(this._box);

  /// Name of the Hive box that holds reward progress.
  static const String boxName = 'rewards';
  static const String _earnedKey = 'earned';

  final Box<dynamic> _box;

  @override
  Set<String> earnedIds() {
    final dynamic raw = _box.get(_earnedKey);
    if (raw is List) return raw.cast<String>().toSet();
    return <String>{};
  }

  @override
  void save(Set<String> ids) => _box.put(_earnedKey, ids.toList());
}
