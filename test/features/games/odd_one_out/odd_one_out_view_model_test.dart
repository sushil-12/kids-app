import 'package:brightmind_kids/src/core/services/feature_flags.dart';
import 'package:brightmind_kids/src/features/games/odd_one_out/data/odd_item.dart';
import 'package:brightmind_kids/src/features/games/odd_one_out/view_model/odd_one_out_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  OddOneOutState read() => container.read(oddOneOutProvider);
  OddOneOutViewModel vm() => container.read(oddOneOutProvider.notifier);

  // These tests assert the baseline (medium) grid via [countFor], so adaptive
  // difficulty is held off; adaptive behaviour is covered in test/features/adaptive.
  setUp(
    () => container = ProviderContainer(
      overrides: <Override>[
        featureFlagStoreProvider.overrideWithValue(
          EphemeralFeatureFlagStore(
            <String, bool>{FeatureFlagKeys.adaptiveDifficulty: false},
          ),
        ),
      ],
    ),
  );
  tearDown(() => container.dispose());

  group('OddOneOutViewModel generation', () {
    test('every round has exactly one odd tile and the rest identical', () {
      for (int i = 0; i < 200; i++) {
        final OddOneOutState s = read();

        // The grid has the expected count and a valid odd index.
        expect(s.tiles.length, OddOneOutState.countFor(s.round));
        expect(s.oddIndex, inInclusiveRange(0, s.tiles.length - 1));

        final OddItem odd = s.tiles[s.oddIndex];
        // The odd tile is unlike every other tile…
        for (int j = 0; j < s.tiles.length; j++) {
          if (j == s.oddIndex) continue;
          expect(s.tiles[j] == odd, isFalse, reason: 'tile $j matches the odd');
        }
        // …and all the others are identical to each other.
        final OddItem common =
            s.tiles[s.oddIndex == 0 ? s.tiles.length - 1 : 0];
        expect(
          s.tiles.where((OddItem t) => t == common).length,
          s.tiles.length - 1,
        );

        vm().choose(s.oddIndex);
        vm().nextRound();
      }
    });
  });

  group('OddOneOutViewModel round flow', () {
    test('a wrong (matching) tap never advances or solves the round', () {
      final OddOneOutState start = read();
      final int wrong = start.oddIndex == 0 ? 1 : 0;

      vm().choose(wrong);

      expect(read().solved, isFalse);
      expect(read().round, start.round);
    });

    test('finding the odd tile across five rounds completes the game', () {
      for (int round = 1; round <= OddOneOutState.totalRounds; round++) {
        expect(read().round, round);
        vm().choose(read().oddIndex);
        expect(read().solved, isTrue);
        vm().nextRound();
      }

      expect(read().isComplete, isTrue);
      expect(read().roundsDone, OddOneOutState.totalRounds);
    });

    test('reset starts a fresh first round', () {
      vm().choose(read().oddIndex);
      vm().nextRound();
      vm().reset();

      final OddOneOutState s = read();
      expect(s.round, 1);
      expect(s.solved, isFalse);
      expect(s.completed, isFalse);
    });
  });
}
