import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/creative_artwork.dart';
import '../data/creative_store.dart';

/// Injected persistence. Overridden in `main()` with the Hive-backed store once
/// its box is open; overridden again with an in-memory fake in tests.
final creativeStoreProvider = Provider<CreativeStore>(
  (Ref ref) => throw UnimplementedError(
    'creativeStoreProvider must be overridden in main() with a CreativeStore',
  ),
);

/// Owns the child's saved drawings. Loads from the [CreativeStore] on build and
/// persists every change, so the gallery survives app restarts.
class MyArtViewModel extends Notifier<List<CreativeArtwork>> {
  CreativeStore get _store => ref.read(creativeStoreProvider);

  @override
  List<CreativeArtwork> build() => _store.readAll();

  /// Saves a new drawing and refreshes the in-memory list (newest first).
  void add(CreativeArtwork artwork) {
    _store.save(artwork);
    state = _store.readAll();
  }

  /// Permanently removes a drawing (guard this behind the parent gate in the UI).
  void remove(String id) {
    _store.delete(id);
    state = _store.readAll();
  }
}

final myArtProvider =
    NotifierProvider<MyArtViewModel, List<CreativeArtwork>>(MyArtViewModel.new);
