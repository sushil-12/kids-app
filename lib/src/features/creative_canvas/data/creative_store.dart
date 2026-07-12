import 'package:hive_ce_flutter/hive_flutter.dart';

import 'creative_artwork.dart';

/// Persistence boundary for saved Creative-Canvas drawings. Behind an interface
/// so the view-model can be unit-tested with an in-memory fake — no Hive setup.
abstract interface class CreativeStore {
  /// Every saved drawing, newest first.
  List<CreativeArtwork> readAll();

  /// Persists (or replaces) one drawing.
  void save(CreativeArtwork artwork);

  /// Removes the drawing with [id]; a no-op if it isn't there.
  void delete(String id);
}

/// Hive-backed [CreativeStore]. The box is opened once at app start (see
/// `main.dart`); each drawing is stored under its own id as a plain map, so no
/// Hive adapters are required.
class HiveCreativeStore implements CreativeStore {
  HiveCreativeStore(this._box);

  /// Name of the Hive box that holds saved drawings.
  static const String boxName = 'creative_artwork';

  final Box<dynamic> _box;

  @override
  List<CreativeArtwork> readAll() {
    final List<CreativeArtwork> art = <CreativeArtwork>[];
    for (final dynamic raw in _box.values) {
      final CreativeArtwork? a = CreativeArtwork.fromMap(raw);
      if (a != null) art.add(a);
    }
    art.sort(
      (CreativeArtwork a, CreativeArtwork b) =>
          b.createdAtMs.compareTo(a.createdAtMs),
    );
    return art;
  }

  @override
  void save(CreativeArtwork artwork) => _box.put(artwork.id, artwork.toMap());

  @override
  void delete(String id) => _box.delete(id);
}
