import 'package:hive_ce_flutter/hive_flutter.dart';

import 'child_profile.dart';

/// Persistence boundary for the child's profile. Behind an interface so the
/// view-model can be unit-tested with an in-memory store, with no Hive setup.
abstract interface class ProfileStore {
  /// The saved profile, or null if onboarding has not been completed.
  ChildProfile? read();

  /// Persists (or replaces) the child's profile.
  void save(ChildProfile profile);

  /// Clears the profile (e.g. "Delete Profile & Data" in settings).
  void clear();
}

/// Hive-backed [ProfileStore]. The box is opened once at app start (see
/// `main.dart`). The presence of an [_ageBandKey] marks onboarding as done.
class HiveProfileStore implements ProfileStore {
  HiveProfileStore(this._box);

  /// Name of the Hive box that holds the child's profile.
  static const String boxName = 'profile';
  static const String _nameKey = 'name';
  static const String _ageBandKey = 'ageBand';
  static const String _buddyKey = 'buddyId';

  final Box<dynamic> _box;

  @override
  ChildProfile? read() {
    final dynamic ageBand = _box.get(_ageBandKey);
    // Onboarding is only complete once an age band has been chosen.
    if (ageBand is! String) return null;
    final dynamic name = _box.get(_nameKey);
    final dynamic buddyId = _box.get(_buddyKey);
    return ChildProfile(
      name: name is String ? name : '',
      ageBand: AgeBand.fromToken(ageBand),
      buddyId: buddyId is String ? buddyId : '',
    );
  }

  @override
  void save(ChildProfile profile) {
    _box
      ..put(_nameKey, profile.name)
      ..put(_ageBandKey, profile.ageBand.token)
      ..put(_buddyKey, profile.buddyId);
  }

  @override
  void clear() => _box.clear();
}
