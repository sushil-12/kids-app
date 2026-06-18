import 'package:brightmind_kids/src/features/profile/data/buddy.dart';
import 'package:brightmind_kids/src/features/profile/data/child_profile.dart';
import 'package:brightmind_kids/src/features/profile/data/profile_repository.dart';
import 'package:brightmind_kids/src/features/profile/view_model/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [ProfileStore] standing in for Hive. Persists across containers.
class FakeProfileStore implements ProfileStore {
  ChildProfile? _profile;

  @override
  ChildProfile? read() => _profile;

  @override
  void save(ChildProfile profile) => _profile = profile;

  @override
  void clear() => _profile = null;
}

void main() {
  late FakeProfileStore store;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: <Override>[profileStoreProvider.overrideWithValue(store)],
      );

  ChildProfile? read() => container.read(profileProvider);
  ProfileViewModel vm() => container.read(profileProvider.notifier);

  setUp(() {
    store = FakeProfileStore();
    container = makeContainer();
  });
  tearDown(() => container.dispose());

  test('there is no profile before onboarding', () {
    expect(read(), isNull);
  });

  test('completing onboarding saves name, age band and buddy', () {
    vm().completeOnboarding(
      name: '  Maya  ',
      ageBand: AgeBand.senior,
      buddyId: 'panda',
    );
    final ChildProfile? p = read();
    expect(p, isNotNull);
    expect(p!.name, 'Maya'); // trimmed
    expect(p.ageBand, AgeBand.senior);
    expect(p.buddy.id, 'panda');
    expect(p.hasName, isTrue);
  });

  test('an empty name is allowed and reported via hasName', () {
    vm().completeOnboarding(
      name: '   ',
      ageBand: AgeBand.junior,
      buddyId: kBuddies.first.id,
    );
    expect(read()!.name, '');
    expect(read()!.hasName, isFalse);
  });

  test('the profile survives a restart', () {
    vm().completeOnboarding(
      name: 'Aarav',
      ageBand: AgeBand.junior,
      buddyId: 'fox',
    );
    container.dispose();

    container = makeContainer();
    expect(read()!.name, 'Aarav');
    expect(read()!.ageBand, AgeBand.junior);
    expect(read()!.buddy.id, 'fox');
  });

  test('setAgeBand updates and persists the band', () {
    vm().completeOnboarding(
      name: 'Maya',
      ageBand: AgeBand.junior,
      buddyId: 'tiger',
    );
    vm().setAgeBand(AgeBand.senior);
    expect(read()!.ageBand, AgeBand.senior);

    container.dispose();
    container = makeContainer();
    expect(read()!.ageBand, AgeBand.senior);
  });

  test('deleteProfile clears the profile and data', () {
    vm().completeOnboarding(
      name: 'Maya',
      ageBand: AgeBand.junior,
      buddyId: 'tiger',
    );
    vm().deleteProfile();
    expect(read(), isNull);
    expect(store.read(), isNull);
  });

  test('an unknown buddy id falls back to the default buddy', () {
    const ChildProfile p =
        ChildProfile(name: 'X', ageBand: AgeBand.junior, buddyId: 'nope');
    expect(p.buddy, kDefaultBuddy);
  });
}
