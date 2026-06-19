import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

abstract interface class ContentCache {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

class HiveContentCache implements ContentCache {
  const HiveContentCache(this._box);

  final Box<String> _box;

  @override
  Future<String?> get(String key) async => _box.get(key);

  @override
  Future<void> set(String key, String value) => _box.put(key, value);
}

class EphemeralContentCache implements ContentCache {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async => _store[key] = value;
}

final contentCacheProvider = Provider<ContentCache>(
  (_) => EphemeralContentCache(),
);
