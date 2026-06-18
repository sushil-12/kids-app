import 'package:flutter/foundation.dart';

import 'buddy.dart';

/// The age band a child belongs to. Drives which content (games, pages) is
/// surfaced first, so a 2–4 child and a 5–6 child see an age-appropriate app.
enum AgeBand {
  /// 2–4 years.
  junior,

  /// 5–6 years.
  senior;

  /// Stable token persisted in Hive. Never rename these.
  String get token => name;

  /// Parses a persisted token, defaulting to [junior] for unknown/missing data.
  static AgeBand fromToken(String? token) => AgeBand.values.firstWhere(
        (AgeBand b) => b.token == token,
        orElse: () => AgeBand.junior,
      );
}

/// The child's on-device profile: who they are and what content suits them.
///
/// COPPA/GDPR-K: this is the *only* personal data we hold, it never leaves the
/// device (Hive), and the name is optional (see CLAUDE.md §7).
@immutable
class ChildProfile {
  const ChildProfile({
    required this.name,
    required this.ageBand,
    required this.buddyId,
  });

  /// The child's display name. May be empty — the name field is optional.
  final String name;

  /// Which age band's content to surface.
  final AgeBand ageBand;

  /// Id of the chosen [Buddy] (see [buddy]).
  final String buddyId;

  /// The resolved buddy, falling back to [kDefaultBuddy] if the id is unknown.
  Buddy get buddy => buddyById(buddyId) ?? kDefaultBuddy;

  /// Whether a name was provided (controls personalized greetings).
  bool get hasName => name.trim().isNotEmpty;

  ChildProfile copyWith({String? name, AgeBand? ageBand, String? buddyId}) =>
      ChildProfile(
        name: name ?? this.name,
        ageBand: ageBand ?? this.ageBand,
        buddyId: buddyId ?? this.buddyId,
      );

  @override
  bool operator ==(Object other) =>
      other is ChildProfile &&
      other.name == name &&
      other.ageBand == ageBand &&
      other.buddyId == buddyId;

  @override
  int get hashCode => Object.hash(name, ageBand, buddyId);
}
