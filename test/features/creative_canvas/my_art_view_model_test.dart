import 'package:brightmind_kids/src/features/creative_canvas/data/creative_artwork.dart';
import 'package:brightmind_kids/src/features/creative_canvas/data/creative_store.dart';
import 'package:brightmind_kids/src/features/creative_canvas/view_model/my_art_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [CreativeStore] so the view-model can be tested without Hive.
class _FakeCreativeStore implements CreativeStore {
  final Map<String, CreativeArtwork> _items = <String, CreativeArtwork>{};

  @override
  List<CreativeArtwork> readAll() {
    final List<CreativeArtwork> all = _items.values.toList();
    all.sort(
      (CreativeArtwork a, CreativeArtwork b) =>
          b.createdAtMs.compareTo(a.createdAtMs),
    );
    return all;
  }

  @override
  void save(CreativeArtwork artwork) => _items[artwork.id] = artwork;

  @override
  void delete(String id) => _items.remove(id);
}

CreativeArtwork _art(String id, int ms) =>
    CreativeArtwork(id: id, createdAtMs: ms, pngBase64: 'AAAA');

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: <Override>[
        creativeStoreProvider.overrideWithValue(_FakeCreativeStore()),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('starts empty', () {
    expect(container.read(myArtProvider), isEmpty);
  });

  test('add then remove updates the gallery', () {
    final MyArtViewModel vm = container.read(myArtProvider.notifier);
    vm.add(_art('a', 1));
    expect(container.read(myArtProvider), hasLength(1));

    vm.remove('a');
    expect(container.read(myArtProvider), isEmpty);
  });

  test('gallery is sorted newest first', () {
    final MyArtViewModel vm = container.read(myArtProvider.notifier);
    vm
      ..add(_art('old', 100))
      ..add(_art('new', 300))
      ..add(_art('mid', 200));

    final List<String> ids =
        container.read(myArtProvider).map((CreativeArtwork a) => a.id).toList();
    expect(ids, <String>['new', 'mid', 'old']);
  });

  test('CreativeArtwork survives a map round-trip', () {
    final CreativeArtwork a = _art('x', 42);
    expect(CreativeArtwork.fromMap(a.toMap()), a);
  });

  test('fromMap rejects malformed data', () {
    expect(CreativeArtwork.fromMap(<String, dynamic>{'id': 1}), isNull);
    expect(CreativeArtwork.fromMap('nope'), isNull);
  });
}
