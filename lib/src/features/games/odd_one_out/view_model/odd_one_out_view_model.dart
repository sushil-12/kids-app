import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../adaptive/data/difficulty.dart';
import '../../../adaptive/view_model/adaptive_view_model.dart';
import '../../shared/shape_view.dart';
import '../data/odd_item.dart';

/// Immutable state for one round of Odd-One-Out ("Which one is different?").
@immutable
class OddOneOutState {
  const OddOneOutState({
    required this.tiles,
    required this.oddIndex,
    required this.round,
    this.solved = false,
    this.completed = false,
    this.struggled = false,
  });

  /// The grid of tiles; all identical except the one at [oddIndex].
  final List<OddItem> tiles;

  /// Index of the tile that differs — the one to tap.
  final int oddIndex;

  /// 1-based current round.
  final int round;

  /// Whether the odd tile has been found this round.
  final bool solved;

  /// Whether every round is finished (drives the celebration).
  final bool completed;

  /// Whether the child mis-tapped at least once before solving this round.
  /// Fed to the adaptive engine as the round's struggle signal (never shown to
  /// the child — there is no fail state).
  final bool struggled;

  static const int totalRounds = 5;

  /// Tiles per round at each difficulty — the grid grows a little as the child
  /// warms up, which keeps it interesting without ever adding pressure. Counts
  /// stay within 4..9 so the existing grid layout never overflows.
  static const List<int> _countPerRound = <int>[4, 4, 6, 6, 9]; // medium
  static const Map<DifficultyLevel, List<int>> _countByLevel =
      <DifficultyLevel, List<int>>{
    DifficultyLevel.easy: <int>[4, 4, 4, 6, 6],
    DifficultyLevel.medium: _countPerRound,
    DifficultyLevel.hard: <int>[6, 6, 9, 9, 9],
  };

  static int _idx(int round) =>
      (round - 1).clamp(0, _countPerRound.length - 1);

  /// Default (medium) tile count for [round]. Used when adaptive difficulty is
  /// off and by tests asserting the baseline grid.
  static int countFor(int round) => _countPerRound[_idx(round)];

  static int countAt(DifficultyLevel level, int round) =>
      _countByLevel[level]![_idx(round)];

  bool get isComplete => completed;
  int get roundsDone => completed ? totalRounds : round - 1;

  OddOneOutState copyWith({bool? solved, bool? completed, bool? struggled}) =>
      OddOneOutState(
        tiles: tiles,
        oddIndex: oddIndex,
        round: round,
        solved: solved ?? this.solved,
        completed: completed ?? this.completed,
        struggled: struggled ?? this.struggled,
      );
}

/// Owns Odd-One-Out across five rounds. Each round fills a grid with one common
/// item and a single odd one that differs by color or by shape. No fail state:
/// a wrong tap is handled by the view (a gentle wobble); only the odd tile
/// advances play.
class OddOneOutViewModel extends Notifier<OddOneOutState> {
  final math.Random _rng = math.Random();

  /// Bright, easy-to-tell-apart subset of the palette.
  static const List<Color> _palette = <Color>[
    AppColors.coral,
    AppColors.teal,
    AppColors.yellow,
    AppColors.purple,
    AppColors.green,
    AppColors.blue,
    AppColors.pink,
    AppColors.orange,
  ];

  @override
  OddOneOutState build() => _round(1);

  /// The difficulty for the next round. When adaptive difficulty is off this is
  /// always [DifficultyLevel.medium], i.e. the original behaviour.
  DifficultyLevel _difficulty() {
    if (!ref.read(featureFlagsProvider).adaptiveDifficulty) {
      return DifficultyLevel.medium;
    }
    return ref.read(adaptiveProvider.notifier).difficultyFor(GameId.oddOneOut);
  }

  OddOneOutState _round(int round) {
    final DifficultyLevel level = _difficulty();
    final int count = OddOneOutState.countAt(level, round);

    // The element every tile shares.
    final ShapeKind commonShape =
        ShapeKind.values[_rng.nextInt(ShapeKind.values.length)];
    final Color commonColor = _palette[_rng.nextInt(_palette.length)];

    // The odd one differs by color or by shape. Color reads most clearly, so
    // easier rounds always use a color difference; harder rounds lean on the
    // subtler shape difference.
    final bool colorDiff = switch (level) {
      DifficultyLevel.easy => true,
      DifficultyLevel.medium => _rng.nextBool(),
      DifficultyLevel.hard => _rng.nextInt(4) == 0,
    };
    final OddItem odd = colorDiff
        ? OddItem(commonShape, _differentColor(commonColor))
        : OddItem(_differentShape(commonShape), commonColor);

    final OddItem common = OddItem(commonShape, commonColor);
    final int oddIndex = _rng.nextInt(count);
    final List<OddItem> tiles = <OddItem>[
      for (int i = 0; i < count; i++) i == oddIndex ? odd : common,
    ];

    return OddOneOutState(tiles: tiles, oddIndex: oddIndex, round: round);
  }

  Color _differentColor(Color from) {
    Color c;
    do {
      c = _palette[_rng.nextInt(_palette.length)];
    } while (c == from);
    return c;
  }

  ShapeKind _differentShape(ShapeKind from) {
    ShapeKind s;
    do {
      s = ShapeKind.values[_rng.nextInt(ShapeKind.values.length)];
    } while (s == from);
    return s;
  }

  /// Records finding the odd tile. A wrong tap doesn't advance or fail the round
  /// (the view shows a gentle wobble) but is noted as a struggle so difficulty
  /// can ease. On solving, the round's struggle signal feeds the adaptive engine.
  void choose(int index) {
    if (state.solved || state.completed) return;
    if (index == state.oddIndex) {
      state = state.copyWith(solved: true);
      if (ref.read(featureFlagsProvider).adaptiveDifficulty) {
        ref
            .read(adaptiveProvider.notifier)
            .recordRound(GameId.oddOneOut, struggled: state.struggled);
      }
    } else {
      state = state.copyWith(struggled: true);
    }
  }

  /// Advances to the next round, or finishes after the last one.
  void nextRound() {
    if (state.round >= OddOneOutState.totalRounds) {
      state = state.copyWith(completed: true);
    } else {
      state = _round(state.round + 1);
    }
  }

  void reset() => state = _round(1);
}

final oddOneOutProvider =
    NotifierProvider<OddOneOutViewModel, OddOneOutState>(OddOneOutViewModel.new);
