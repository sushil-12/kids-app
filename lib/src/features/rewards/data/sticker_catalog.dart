import 'sticker.dart';

/// The full set of stickers a child can collect. Order is the display order in
/// the Sticker Room. Add new stickers to the END only — ids are persisted, so
/// existing ones must keep their position-independent id.
const List<Sticker> kStickers = <Sticker>[
  Sticker(id: 'lion', emoji: '🦁'),
  Sticker(id: 'tiger', emoji: '🐯'),
  Sticker(id: 'dog', emoji: '🐶'),
  Sticker(id: 'cat', emoji: '🐱'),
  Sticker(id: 'rabbit', emoji: '🐰'),
  Sticker(id: 'fox', emoji: '🦊'),
  Sticker(id: 'panda', emoji: '🐼'),
  Sticker(id: 'koala', emoji: '🐨'),
  Sticker(id: 'unicorn', emoji: '🦄'),
  Sticker(id: 'frog', emoji: '🐸'),
  Sticker(id: 'monkey', emoji: '🐵'),
  Sticker(id: 'butterfly', emoji: '🦋'),
  Sticker(id: 'fish', emoji: '🐠'),
  Sticker(id: 'turtle', emoji: '🐢'),
  Sticker(id: 'owl', emoji: '🦉'),
  Sticker(id: 'bee', emoji: '🐝'),
  Sticker(id: 'star', emoji: '⭐'),
  Sticker(id: 'rainbow', emoji: '🌈'),
  Sticker(id: 'flower', emoji: '🌸'),
  Sticker(id: 'apple', emoji: '🍎'),
  Sticker(id: 'rocket', emoji: '🚀'),
  Sticker(id: 'balloon', emoji: '🎈'),
  Sticker(id: 'palette', emoji: '🎨'),
  Sticker(id: 'crown', emoji: '👑'),
  // Themed coloring-page rewards (see each ColoringTemplate.stickerRewardId).
  Sticker(id: 'sun', emoji: '☀️'),
  Sticker(id: 'house', emoji: '🏠'),
];

/// Looks up a sticker by [id], or null if it is not in the catalog. Useful for
/// content-authored rewards (e.g. a coloring page's `stickerRewardId`).
Sticker? stickerById(String id) {
  for (final Sticker s in kStickers) {
    if (s.id == id) return s;
  }
  return null;
}
