import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/feature_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../adaptive/data/difficulty.dart';
import '../../../adaptive/view_model/adaptive_view_model.dart';
import '../../shared/shape_view.dart';

/// One hole/shape pairing. A child drags the matching shape onto its [kind]
/// hole; [placed] flips true on a correct drop.
@immutable
class SortableShape {
  const SortableShape({
    required this.kind,
    required this.color,
    this.placed = false,
  });

  final ShapeKind kind;
  final Color color;
  final bool placed;

  SortableShape copyWith({bool? placed}) =>
      SortableShape(kind: kind, color: color, placed: placed ?? this.placed);
}

/// Immutable state for Shape Sorter.
@immutable
class ShapeSorterState {
  const ShapeSorterState({required this.holes, required this.tray});

  /// Fixed-order holes (targets).
  final List<SortableShape> holes;

  /// Shuffled kinds still waiting in the tray.
  final List<ShapeKind> tray;

  int get placedCount => holes.where((SortableShape s) => s.placed).length;
  int get total => holes.length;
  bool get isComplete => placedCount == total && total > 0;
}

/// Owns Shape Sorter state and exposes drag intents. No fail state: a wrong
/// drop is simply rejected by the view (gentle wobble) and never mutates here.
class ShapeSorterViewModel extends Notifier<ShapeSorterState> {
  // Ordered by how distinct the silhouette is: the first three read most
  // clearly, while star and heart are the trickier, more similar silhouettes
  // brought in as difficulty rises.
  static const List<ShapeKind> _kinds = <ShapeKind>[
    ShapeKind.circle,
    ShapeKind.square,
    ShapeKind.triangle,
    ShapeKind.star,
    ShapeKind.heart,
  ];
  static const List<Color> _colors = <Color>[
    AppColors.coral,
    AppColors.teal,
    AppColors.yellow,
    AppColors.purple,
    AppColors.green,
  ];

  /// How many shapes to sort at each difficulty — more shapes (and the trickier
  /// star/heart silhouettes) make matching harder, never unfair.
  static int countFor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.easy => 3,
        DifficultyLevel.medium => 4,
        DifficultyLevel.hard => 5,
      };

  @override
  ShapeSorterState build() => _newGame();

  /// The difficulty for a new board. When adaptive difficulty is off this is
  /// always [DifficultyLevel.medium], i.e. the original four-shape board.
  DifficultyLevel _difficulty() {
    if (!ref.read(featureFlagsProvider).adaptiveDifficulty) {
      return DifficultyLevel.medium;
    }
    return ref.read(adaptiveProvider.notifier).difficultyFor(GameId.shapeSorter);
  }

  ShapeSorterState _newGame() {
    final int count = countFor(_difficulty());
    final List<SortableShape> holes = <SortableShape>[
      for (int i = 0; i < count; i++)
        SortableShape(kind: _kinds[i], color: _colors[i]),
    ];
    final List<ShapeKind> tray =
        List<ShapeKind>.of(_kinds.take(count))..shuffle(math.Random());
    return ShapeSorterState(holes: holes, tray: tray);
  }

  /// Marks the hole matching [kind] as filled and removes it from the tray.
  /// Finishing the board is a clean success signal for the adaptive engine
  /// (wrong drops are rejected by the view and never reach here).
  void place(ShapeKind kind) {
    final bool wasComplete = state.isComplete;
    final List<SortableShape> holes = <SortableShape>[
      for (final SortableShape s in state.holes)
        s.kind == kind ? s.copyWith(placed: true) : s,
    ];
    final List<ShapeKind> tray = List<ShapeKind>.of(state.tray)..remove(kind);
    final ShapeSorterState next = ShapeSorterState(holes: holes, tray: tray);
    state = next;
    // Happy "pop" each time a shape clicks into its home.
    ref.read(audioServiceProvider).sfx(Sfx.pop);
    if (!wasComplete &&
        next.isComplete &&
        ref.read(featureFlagsProvider).adaptiveDifficulty) {
      ref
          .read(adaptiveProvider.notifier)
          .recordRound(GameId.shapeSorter, struggled: false);
    }
  }

  void reset() => state = _newGame();
}

final shapeSorterProvider =
    NotifierProvider<ShapeSorterViewModel, ShapeSorterState>(ShapeSorterViewModel.new);
