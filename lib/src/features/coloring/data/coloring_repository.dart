import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coloring_page.dart';

/// Repository = source of truth for coloring content (MVVM data layer).
/// In Phase 1 the manifest is bundled; later this can fetch remote packs.
class ColoringRepository {
  const ColoringRepository();

  List<ColoringPage> pagesForCategory(String category) {
    return _all.where((ColoringPage p) => p.category == category).toList();
  }

  ColoringPage byId(String id) =>
      _all.firstWhere((ColoringPage p) => p.id == id, orElse: () => _all.first);

  static const List<ColoringPage> _all = <ColoringPage>[
    ColoringPage(
      id: 'lion',
      title: 'Lion',
      category: 'animals',
      assetPath: 'assets/coloring_pages/lion.svg',
      isPremium: false,
      stickerRewardId: 'sticker_lion',
    ),
    ColoringPage(
      id: 'puppy',
      title: 'Puppy',
      category: 'animals',
      assetPath: 'assets/coloring_pages/puppy.svg',
      isPremium: false,
      stickerRewardId: 'sticker_puppy',
    ),
    ColoringPage(
      id: 'rocket',
      title: 'Rocket',
      category: 'vehicles',
      assetPath: 'assets/coloring_pages/rocket.svg',
      isPremium: true,
      stickerRewardId: 'sticker_rocket',
    ),
    // ...content pipeline appends the remaining pages here.
  ];
}

final coloringRepositoryProvider =
    Provider<ColoringRepository>((Ref ref) => const ColoringRepository());
