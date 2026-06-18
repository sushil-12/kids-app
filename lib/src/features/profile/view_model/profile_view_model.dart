import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/buddy.dart';
import '../data/child_profile.dart';
import '../data/profile_repository.dart';

/// Injected persistence. Overridden in `main()` with the Hive-backed store once
/// its box is open; overridden again with an in-memory fake in tests.
final profileStoreProvider = Provider<ProfileStore>(
  (Ref ref) => throw UnimplementedError(
    'profileStoreProvider must be overridden in main() with a ProfileStore',
  ),
);

/// Owns the child's profile. Loads from the [ProfileStore] on build and
/// persists every change, so the chosen name / age band / buddy survive
/// restarts. The profile being null means onboarding has not happened yet.
class ProfileViewModel extends Notifier<ChildProfile?> {
  ProfileStore get _store => ref.read(profileStoreProvider);

  @override
  ChildProfile? build() => _store.read();

  /// Saves the first-run setup and marks onboarding complete. [name] is
  /// trimmed; an empty name is allowed (the field is optional).
  void completeOnboarding({
    required String name,
    required AgeBand ageBand,
    required String buddyId,
  }) {
    final ChildProfile profile = ChildProfile(
      name: name.trim(),
      ageBand: ageBand,
      buddyId: buddyId,
    );
    _store.save(profile);
    state = profile;
  }

  /// Changes the age band later (e.g. from Parent Settings).
  void setAgeBand(AgeBand ageBand) {
    final ChildProfile? current = state;
    if (current == null) return;
    final ChildProfile next = current.copyWith(ageBand: ageBand);
    _store.save(next);
    state = next;
  }

  /// Clears the profile and data (Delete Profile & Data).
  void deleteProfile() {
    _store.clear();
    state = null;
  }
}

final profileProvider =
    NotifierProvider<ProfileViewModel, ChildProfile?>(ProfileViewModel.new);

/// The current buddy, resolving to [kDefaultBuddy] before onboarding so widgets
/// that show the buddy never have to null-check.
final buddyProvider = Provider<Buddy>(
  (Ref ref) => ref.watch(profileProvider)?.buddy ?? kDefaultBuddy,
);
