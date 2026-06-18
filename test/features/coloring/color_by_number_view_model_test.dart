import 'package:brightmind_kids/src/features/coloring/data/by_number_palette.dart';
import 'package:brightmind_kids/src/features/coloring/data/coloring_templates.dart';
import 'package:brightmind_kids/src/features/coloring/view_model/color_by_number_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  // The sun page has a small, known number map: sky→5, rays→2, body→1.
  ByNumberState read() => container.read(byNumberProvider('sun'));
  ByNumberViewModel vm() => container.read(byNumberProvider('sun').notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('a matching number fills the region with the right color', () {
    vm().selectNumber(5); // sky
    vm().tapRegion('sky');

    expect(read().fills['sky'], byNumberColor(5));
    expect(read().filledRegions, 1);
  });

  test('a mismatched number nudges instead of filling (no fail)', () {
    vm().selectNumber(1); // body is 1, sky is 5
    final int before = read().wrongNudge;
    vm().tapRegion('sky');

    expect(read().fills.containsKey('sky'), isFalse);
    expect(read().wrongNudge, before + 1);
  });

  test('tapping an already-filled region is a no-op', () {
    vm().selectNumber(1);
    vm().tapRegion('body');
    final int nudge = read().wrongNudge;

    vm().selectNumber(5);
    vm().tapRegion('body'); // already done

    expect(read().fills['body'], byNumberColor(1));
    expect(read().wrongNudge, nudge, reason: 'no nudge for a finished region');
  });

  test('filling every numbered region completes the picture', () {
    final Map<String, int> map = read().template.byNumber;
    for (final MapEntry<String, int> e in map.entries) {
      vm().selectNumber(e.value);
      vm().tapRegion(e.key);
    }

    expect(read().isComplete, isTrue);
    expect(read().filledRegions, map.length);
  });

  test('reset clears all fills', () {
    vm().selectNumber(1);
    vm().tapRegion('body');
    vm().reset();

    expect(read().filledRegions, 0);
    expect(read().isComplete, isFalse);
  });

  test('all by-number templates only reference valid palette numbers', () {
    for (final dynamic t in kColoringTemplates) {
      final Map<String, int> map = t.byNumber as Map<String, int>;
      for (final int n in map.values) {
        expect(
          byNumberColor(n),
          isNotNull,
          reason: 'template "${t.id}" uses out-of-range number $n',
        );
      }
    }
  });
}
