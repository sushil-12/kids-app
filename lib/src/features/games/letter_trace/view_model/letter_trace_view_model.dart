import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for Letter Trace. [dots] are normalized (0..1) guide points
/// laid along the letter's strokes; the child sweeps a finger through them.
@immutable
class LetterTraceState {
  const LetterTraceState({
    required this.letter,
    required this.dots,
    this.visited = const <int>{},
    this.drawnPoints = const <Offset>[],
  });

  final String letter;
  final List<Offset> dots;
  final Set<int> visited;

  /// Raw normalized finger positions collected during the trace, used to draw
  /// the ink trail. A sentinel `Offset(-1, -1)` separates lifted strokes.
  final List<Offset> drawnPoints;

  int get total => dots.length;
  int get progress => visited.length;
  bool get isComplete => dots.isNotEmpty && visited.length == dots.length;

  LetterTraceState copyWith({Set<int>? visited, List<Offset>? drawnPoints}) =>
      LetterTraceState(
        letter: letter,
        dots: dots,
        visited: visited ?? this.visited,
        drawnPoints: drawnPoints ?? this.drawnPoints,
      );
}

/// Owns Letter Trace state. Completion is forgiving: a guide dot lights up when
/// the finger passes near it, in any order (House Rule §5 — no fail state).
class LetterTraceViewModel extends Notifier<LetterTraceState> {
  static const double _hitRadius = 0.13;

  /// Normalized guide dots per letter (x →, y ↓).
  static const Map<String, List<Offset>> _letters = <String, List<Offset>>{
    'A': <Offset>[
      Offset(0.5, 0.08), Offset(0.35, 0.5), Offset(0.2, 0.92),
      Offset(0.65, 0.5), Offset(0.8, 0.92), Offset(0.5, 0.62),
    ],
    'C': <Offset>[
      Offset(0.8, 0.2), Offset(0.5, 0.08), Offset(0.2, 0.35),
      Offset(0.18, 0.65), Offset(0.5, 0.92), Offset(0.8, 0.8),
    ],
    'O': <Offset>[
      Offset(0.5, 0.06), Offset(0.85, 0.3), Offset(0.85, 0.7),
      Offset(0.5, 0.94), Offset(0.15, 0.7), Offset(0.15, 0.3),
    ],
    'L': <Offset>[
      Offset(0.3, 0.08), Offset(0.3, 0.4), Offset(0.3, 0.72),
      Offset(0.3, 0.92), Offset(0.6, 0.92), Offset(0.85, 0.92),
    ],
    'T': <Offset>[
      Offset(0.15, 0.12), Offset(0.5, 0.12), Offset(0.85, 0.12),
      Offset(0.5, 0.42), Offset(0.5, 0.7), Offset(0.5, 0.92),
    ],
  };

  @override
  LetterTraceState build() => _pick();

  LetterTraceState _pick() {
    final List<String> keys = _letters.keys.toList();
    final String letter = keys[math.Random().nextInt(keys.length)];
    return LetterTraceState(letter: letter, dots: _letters[letter]!);
  }

  /// Lights up any guide dot within reach of the normalized finger [point]
  /// and records the point for the ink trail.
  void touch(Offset point) {
    Set<int>? next;
    for (int i = 0; i < state.dots.length; i++) {
      if (state.visited.contains(i)) continue;
      if ((state.dots[i] - point).distance <= _hitRadius) {
        (next ??= <int>{...state.visited}).add(i);
      }
    }
    state = state.copyWith(
      visited: next,
      drawnPoints: <Offset>[...state.drawnPoints, point],
    );
  }

  /// Called when the finger lifts; inserts a sentinel to break the path.
  void liftPen() {
    if (state.drawnPoints.isNotEmpty) {
      state = state.copyWith(
        drawnPoints: <Offset>[...state.drawnPoints, const Offset(-1, -1)],
      );
    }
  }

  void reset() => state = _pick();
}

final letterTraceProvider =
    NotifierProvider<LetterTraceViewModel, LetterTraceState>(LetterTraceViewModel.new);
