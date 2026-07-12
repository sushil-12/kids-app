import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persistence boundary for the backend admin key. The key authenticates the
/// in-app admin panel to the admin-only backend endpoints (`x-admin-key`).
///
/// It is entered by a parent (behind the parent gate) and stored on-device only
/// — it never ships in the app binary. Behind an interface so the view-model can
/// be unit-tested with an in-memory store, with no Hive setup.
abstract interface class AdminKeyStore {
  /// The saved admin key, or `null` if none has been entered.
  String? read();

  /// Persists (or replaces) the admin key.
  void save(String key);

  /// Clears the stored admin key.
  void clear();
}

/// Hive-backed [AdminKeyStore]. The box is opened once at app start (see
/// `main.dart`).
class HiveAdminKeyStore implements AdminKeyStore {
  const HiveAdminKeyStore(this._box);

  /// Name of the Hive box that holds the admin key.
  static const String boxName = 'admin';
  static const String _keyName = 'adminApiKey';

  final Box<dynamic> _box;

  @override
  String? read() {
    final dynamic v = _box.get(_keyName);
    return v is String && v.isNotEmpty ? v : null;
  }

  @override
  void save(String key) => _box.put(_keyName, key);

  @override
  void clear() => _box.delete(_keyName);
}

/// In-memory [AdminKeyStore] — the default binding and the test binding.
class EphemeralAdminKeyStore implements AdminKeyStore {
  EphemeralAdminKeyStore([this._key]);

  String? _key;

  @override
  String? read() => (_key?.isNotEmpty ?? false) ? _key : null;

  @override
  void save(String key) => _key = key;

  @override
  void clear() => _key = null;
}
