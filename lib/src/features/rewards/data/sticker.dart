import 'package:flutter/foundation.dart';

/// A collectible sticker. Stickers are pure emoji so they stay fully offline,
/// crisp at any size, and need no bundled image assets (House Rule: offline,
/// no asset dependency in Phase 1).
@immutable
class Sticker {
  const Sticker({required this.id, required this.emoji});

  /// Stable identifier persisted in Hive. Never reuse or renumber these — they
  /// are the key to what a child has already earned.
  final String id;

  /// The glyph shown in the sticker book and the win celebration.
  final String emoji;

  @override
  bool operator ==(Object other) => other is Sticker && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
