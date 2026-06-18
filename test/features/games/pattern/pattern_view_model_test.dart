import 'package:brightmind_kids/src/features/games/pattern/data/pattern_element.dart';
import 'package:brightmind_kids/src/features/games/pattern/view_model/pattern_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  PatternState read() => container.read(patternProvider);
  PatternViewModel vm() => container.read(patternProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('PatternViewModel generation', () {
    test('every generated round is internally consistent', () {
      // Run many rounds so the random pattern types are all exercised.
      for (int i = 0; i < 200; i++) {
        final PatternState s = read();

        // The visible run and the three choices are always present.
        expect(s.sequence.length, PatternState.visibleCount);
        expect(s.options.length, 3);

        // The answer index is valid and the options are all distinct.
        expect(s.answerIndex, inInclusiveRange(0, 2));
        expect(s.options.toSet().length, 3);

        // The answer must actually continue the visible pattern: extending the
        // run by one period lands on the same element.
        final PatternElement expected =
            s.sequence[PatternState.visibleCount % s._period];
        expect(
          s.answer,
          expected,
          reason: 'answer should repeat the established pattern',
        );

        vm().choose(s.answerIndex);
        vm().nextRound();
      }
    });
  });

  group('PatternViewModel round flow', () {
    test('a wrong choice never advances or solves the round', () {
      final PatternState start = read();
      final int wrong = (start.answerIndex + 1) % 3;

      vm().choose(wrong);

      expect(read().solved, isFalse);
      expect(read().round, start.round);
    });

    test('correct choices across five rounds complete the game', () {
      for (int round = 1; round <= PatternState.totalRounds; round++) {
        expect(read().round, round);
        vm().choose(read().answerIndex);
        expect(read().solved, isTrue);
        vm().nextRound();
      }

      expect(read().isComplete, isTrue);
      expect(read().roundsDone, PatternState.totalRounds);
    });

    test('reset starts a fresh first round', () {
      vm().choose(read().answerIndex);
      vm().nextRound();
      vm().reset();

      final PatternState s = read();
      expect(s.round, 1);
      expect(s.solved, isFalse);
      expect(s.completed, isFalse);
    });
  });
}

/// The smallest period [p] for which the visible run is a prefix of some unit
/// repeated — i.e. sequence[i] == sequence[i % p] for every i. Derived purely
/// from the run, this lets the test assert the answer continues the pattern
/// without depending on the view-model's internal unit.
extension on PatternState {
  int get _period {
    for (int p = 1; p <= sequence.length; p++) {
      bool ok = true;
      for (int i = 0; i < sequence.length; i++) {
        if (sequence[i] != sequence[i % p]) {
          ok = false;
          break;
        }
      }
      if (ok) return p;
    }
    return sequence.length;
  }
}
