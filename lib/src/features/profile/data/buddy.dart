import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A buddy character the child picks during onboarding. The buddy follows them
/// through the app and claps for them in every win celebration.
///
/// Buddies are bundled, original character illustrations (no third-party or
/// licensed IP) which keeps the app inside the Apple Kids Category compliance
/// rules (see CLAUDE.md §7).
@immutable
class Buddy {
  const Buddy({
    required this.id,
    required this.assetPath,
    required this.color,
  });

  /// Stable identifier persisted in Hive. Never reuse or renumber these — it is
  /// the key to which buddy a child chose.
  final String id;

  /// Bundled illustration shown as the avatar everywhere the buddy appears.
  final String assetPath;

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
  Buddy(
    id: 'girl',
    assetPath: 'assets/images/avatars/avatar_girl.png',
    color: AppColors.pink,
  ),
  Buddy(
    id: 'boy',
    assetPath: 'assets/images/avatars/avatar_boy.png',
    color: AppColors.blue,
  ),
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
