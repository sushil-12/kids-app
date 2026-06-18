import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A buddy character the child picks during onboarding. The buddy follows them
/// through the app and claps for them in every win celebration.
///
/// Buddies are pure emoji so they stay fully offline and need no bundled image
/// assets (same rationale as stickers). They are deliberately *original*
/// characters — no third-party/licensed IP — which keeps the app inside the
/// Apple Kids Category compliance rules (see CLAUDE.md §7). When custom or
/// licensed character art lands later, swap [emoji] for an asset path; nothing
/// else needs to change.
@immutable
class Buddy {
  const Buddy({required this.id, required this.emoji, required this.color});

  /// Stable identifier persisted in Hive. Never reuse or renumber these — it is
  /// the key to which buddy a child chose.
  final String id;

  /// The glyph shown as the avatar everywhere the buddy appears.
  final String emoji;

  /// Theme color for the buddy's selection ring / accents.
  final Color color;

  @override
  bool operator ==(Object other) => other is Buddy && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The buddies a child can choose from, in onboarding display order. Add new
/// buddies to the END only — ids are persisted.
const List<Buddy> kBuddies = <Buddy>[
  Buddy(id: 'tiger', emoji: '🐯', color: AppColors.orange),
  Buddy(id: 'panda', emoji: '🐼', color: AppColors.teal),
  Buddy(id: 'bunny', emoji: '🐰', color: AppColors.pink),
  Buddy(id: 'fox', emoji: '🦊', color: AppColors.coral),
  Buddy(id: 'frog', emoji: '🐸', color: AppColors.green),
  Buddy(id: 'owl', emoji: '🦉', color: AppColors.purple),
];

/// The buddy shown before a child has chosen one (and a safe fallback if a
/// persisted id is ever unknown).
final Buddy kDefaultBuddy = kBuddies.first;

/// Looks up a buddy by its persisted [id], or null if unknown.
Buddy? buddyById(String? id) {
  for (final Buddy b in kBuddies) {
    if (b.id == id) return b;
  }
  return null;
}
