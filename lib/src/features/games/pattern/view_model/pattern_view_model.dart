import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../shared/shape_view.dart';
import '../data/pattern_element.dart';

/// Immutable state for one round of Pattern Sequence ("What's Next?").
///
/// [sequence] is the visible run shown left-to-right, followed on screen by a
/// "?" slot. The child picks from [options]; [answerIndex] is the right one.
@immutable
class PatternState {
  const PatternState({
    required this.sequence,
    required this.options,
    required this.answerIndex,
    required this.round,
    this.solved = false,
    this.completed = false,
  });

  /// The shapes already laid out, in order. The next one is the puzzle.
  final List<PatternElement> sequence;

  /// The three tappable choices below the sequence.
  final List<PatternElement> options;

  /// Index into [options] of the element that correctly continues the pattern.
  final int answerIndex;

  /// 1-based current round.
  final int round;

  /// Whether the current round's correct answer has been chosen.
  final bool solved;

  /// Whether every round is finished (drives the celebration).
  final bool completed;

  static const int totalRounds = 5;

  /// How many slots of the visible run to show before the "?" placeholder.
  static const int visibleCount = 5;

  PatternElement get answer => options[answerIndex];

  bool get isComplete => completed;
  int get roundsDone => completed ? totalRounds : round - 1;

  PatternState copyWith({bool? solved, bool? completed}) => PatternState(
        sequence: sequence,
        options: options,
        answerIndex: answerIndex,
        round: round,
        solved: solved ?? this.solved,
        completed: completed ?? this.completed,
      );
}

/// Owns Pattern Sequence across five rounds. Each round generates a fresh
/// repeating pattern (AB, ABC or AABB) from random shapes + colors, hides the
/// next element, and offers three choices. There is no fail state: a wrong tap
/// is handled by the view (a gentle wobble); only the correct tap advances.
class PatternViewModel extends Notifier<PatternState> {
  final math.Random _rng = math.Random();

  /// Bright, easy-to-tell-apart subset of the palette for pattern elements.
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
  PatternState build() => _round(1);

  PatternState _round(int round) {
    // Choose a pattern shape: AB (2 distinct), ABC (3 distinct), or AABB.
    final int kind = _rng.nextInt(3);
    final int distinct = kind == 1 ? 3 : 2; // ABC needs 3, others 2
    final List<PatternElement> base = _distinctElements(distinct);

    // Build the repeating unit from those base elements.
    final List<PatternElement> unit;
    switch (kind) {
      case 0: // AB
        unit = <PatternElement>[base[0], base[1]];
      case 1: // ABC
        unit = <PatternElement>[base[0], base[1], base[2]];
      default: // AABB
        unit = <PatternElement>[base[0], base[0], base[1], base[1]];
    }

    // The visible run, then the element that should come next.
    final List<PatternElement> sequence = <PatternElement>[
      for (int i = 0; i < PatternState.visibleCount; i++) unit[i % unit.length],
    ];
    final PatternElement answer =
        unit[PatternState.visibleCount % unit.length];

    final List<PatternElement> options = _buildOptions(answer, base);
    return PatternState(
      sequence: sequence,
      options: options,
      answerIndex: options.indexOf(answer),
      round: round,
    );
  }

  /// [n] elements that all differ in both shape and color, so the pattern reads
  /// clearly even for the youngest players.
  List<PatternElement> _distinctElements(int n) {
    final List<ShapeKind> shapes = List<ShapeKind>.of(ShapeKind.values)
      ..shuffle(_rng);
    final List<Color> colors = List<Color>.of(_palette)..shuffle(_rng);
    return <PatternElement>[
      for (int i = 0; i < n; i++) PatternElement(shapes[i], colors[i]),
    ];
  }

  /// Three shuffled choices: the [answer] plus distractors. Distractors prefer
  /// the pattern's own other elements (a believable mistake), topped up with
  /// fresh random elements if needed.
  List<PatternElement> _buildOptions(
    PatternElement answer,
    List<PatternElement> base,
  ) {
    final List<PatternElement> options = <PatternElement>[answer];
    for (final PatternElement e in base) {
      if (options.length >= 3) break;
      if (!options.contains(e)) options.add(e);
    }
    while (options.length < 3) {
      final PatternElement extra = _distinctElements(1).first;
      if (!options.contains(extra)) options.add(extra);
    }
    return options..shuffle(_rng);
  }

  /// Records a correct choice. Wrong choices are ignored here (the view shows
  /// the wobble); this keeps the no-fail rule and never blocks progress.
  void choose(int optionIndex) {
    if (state.solved || state.completed) return;
    if (optionIndex == state.answerIndex) {
      state = state.copyWith(solved: true);
      ref.read(audioServiceProvider).sfx(Sfx.chime);
    }
  }

  /// Advances to the next round, or finishes after the last one.
  void nextRound() {
    if (state.round >= PatternState.totalRounds) {
      state = state.copyWith(completed: true);
    } else {
      state = _round(state.round + 1);
    }
  }

  void reset() => state = _round(1);
}

final patternProvider =
    NotifierProvider<PatternViewModel, PatternState>(PatternViewModel.new);
