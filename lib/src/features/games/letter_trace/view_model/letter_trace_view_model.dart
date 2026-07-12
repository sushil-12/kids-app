import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/audio_service.dart';

/// Immutable state for Letter Trace.
///
/// [strokes] are the letter's pen strokes as normalized (0..1) polylines — they
/// drive both the faint guide drawn behind and the dots the child sweeps
/// through, so the guide and the dots always line up by construction. [dots] is
/// the flattened, de-duplicated set of stroke points (the touch targets).
@immutable
class LetterTraceState {
  const LetterTraceState({
    required this.letterIndex,
    required this.letter,
    required this.strokes,
    required this.dots,
    this.visited = const <int>{},
    this.drawnPoints = const <Offset>[],
  });

  /// Position in the A→Z sequence (0 = 'A', 25 = 'Z').
  final int letterIndex;
  final String letter;
  final List<List<Offset>> strokes;
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
        letterIndex: letterIndex,
        letter: letter,
        strokes: strokes,
        dots: dots,
        visited: visited ?? this.visited,
        drawnPoints: drawnPoints ?? this.drawnPoints,
      );
}

/// Owns Letter Trace state. The game walks the alphabet in order — it always
/// starts at 'A' and advances one letter at a time up to 'Z', then wraps back
/// to 'A' (House Rule §5 — endless, no fail state). Completion is forgiving: a
/// guide dot lights up when the finger passes near it, in any order; we only
/// track which dots were reached, never whether the stroke was "correct".
class LetterTraceViewModel extends Notifier<LetterTraceState> {
  static const double _hitRadius = 0.13;

  /// The 26 letters in trace order. `_alphabet[i]` is the letter shown at
  /// [LetterTraceState.letterIndex] `i`.
  static const List<String> _alphabet = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  /// Each letter as a list of pen strokes; each stroke is a normalized polyline
  /// (x →, y ↓) in stroke order. The view smooths these into the guide glyph.
  static const Map<String, List<List<Offset>>> _letters =
      <String, List<List<Offset>>>{
    'A': <List<Offset>>[
      <Offset>[
        Offset(0.2, 0.92),
        Offset(0.35, 0.5),
        Offset(0.5, 0.08),
        Offset(0.65, 0.5),
        Offset(0.8, 0.92),
      ],
      <Offset>[Offset(0.34, 0.56), Offset(0.66, 0.56)],
    ],
    'B': <List<Offset>>[
      <Offset>[Offset(0.28, 0.08), Offset(0.28, 0.5), Offset(0.28, 0.92)],
      <Offset>[
        Offset(0.28, 0.08),
        Offset(0.62, 0.18),
        Offset(0.62, 0.42),
        Offset(0.28, 0.5),
      ],
      <Offset>[
        Offset(0.28, 0.5),
        Offset(0.68, 0.6),
        Offset(0.68, 0.84),
        Offset(0.28, 0.92),
      ],
    ],
    'C': <List<Offset>>[
      <Offset>[
        Offset(0.78, 0.24),
        Offset(0.6, 0.1),
        Offset(0.32, 0.16),
        Offset(0.16, 0.4),
        Offset(0.16, 0.6),
        Offset(0.32, 0.84),
        Offset(0.6, 0.9),
        Offset(0.78, 0.76),
      ],
    ],
    'D': <List<Offset>>[
      <Offset>[Offset(0.28, 0.08), Offset(0.28, 0.5), Offset(0.28, 0.92)],
      <Offset>[
        Offset(0.28, 0.08),
        Offset(0.55, 0.12),
        Offset(0.74, 0.32),
        Offset(0.76, 0.5),
        Offset(0.74, 0.68),
        Offset(0.55, 0.88),
        Offset(0.28, 0.92),
      ],
    ],
    'E': <List<Offset>>[
      <Offset>[Offset(0.3, 0.1), Offset(0.3, 0.5), Offset(0.3, 0.92)],
      <Offset>[Offset(0.3, 0.1), Offset(0.72, 0.1)],
      <Offset>[Offset(0.3, 0.5), Offset(0.62, 0.5)],
      <Offset>[Offset(0.3, 0.92), Offset(0.72, 0.92)],
    ],
    'F': <List<Offset>>[
      <Offset>[Offset(0.3, 0.1), Offset(0.3, 0.5), Offset(0.3, 0.92)],
      <Offset>[Offset(0.3, 0.1), Offset(0.72, 0.1)],
      <Offset>[Offset(0.3, 0.5), Offset(0.62, 0.5)],
    ],
    'G': <List<Offset>>[
      <Offset>[
        Offset(0.78, 0.24),
        Offset(0.6, 0.1),
        Offset(0.32, 0.16),
        Offset(0.16, 0.4),
        Offset(0.16, 0.62),
        Offset(0.34, 0.86),
        Offset(0.62, 0.9),
        Offset(0.8, 0.74),
        Offset(0.8, 0.58),
        Offset(0.6, 0.58),
      ],
    ],
    'H': <List<Offset>>[
      <Offset>[Offset(0.26, 0.08), Offset(0.26, 0.5), Offset(0.26, 0.92)],
      <Offset>[Offset(0.74, 0.08), Offset(0.74, 0.5), Offset(0.74, 0.92)],
      <Offset>[Offset(0.26, 0.5), Offset(0.74, 0.5)],
    ],
    'I': <List<Offset>>[
      <Offset>[Offset(0.32, 0.1), Offset(0.68, 0.1)],
      <Offset>[Offset(0.5, 0.1), Offset(0.5, 0.5), Offset(0.5, 0.92)],
      <Offset>[Offset(0.32, 0.92), Offset(0.68, 0.92)],
    ],
    'J': <List<Offset>>[
      <Offset>[
        Offset(0.66, 0.1),
        Offset(0.66, 0.62),
        Offset(0.58, 0.84),
        Offset(0.4, 0.9),
        Offset(0.24, 0.78),
        Offset(0.22, 0.64),
      ],
    ],
    'K': <List<Offset>>[
      <Offset>[Offset(0.28, 0.08), Offset(0.28, 0.5), Offset(0.28, 0.92)],
      <Offset>[Offset(0.72, 0.1), Offset(0.28, 0.52)],
      <Offset>[Offset(0.4, 0.45), Offset(0.72, 0.92)],
    ],
    'L': <List<Offset>>[
      <Offset>[
        Offset(0.3, 0.08),
        Offset(0.3, 0.5),
        Offset(0.3, 0.92),
        Offset(0.6, 0.92),
        Offset(0.84, 0.92),
      ],
    ],
    'M': <List<Offset>>[
      <Offset>[
        Offset(0.16, 0.92),
        Offset(0.16, 0.1),
        Offset(0.5, 0.6),
        Offset(0.84, 0.1),
        Offset(0.84, 0.92),
      ],
    ],
    'N': <List<Offset>>[
      <Offset>[
        Offset(0.22, 0.92),
        Offset(0.22, 0.1),
        Offset(0.78, 0.9),
        Offset(0.78, 0.1),
      ],
    ],
    'O': <List<Offset>>[
      <Offset>[
        Offset(0.5, 0.08),
        Offset(0.78, 0.26),
        Offset(0.86, 0.5),
        Offset(0.78, 0.74),
        Offset(0.5, 0.92),
        Offset(0.22, 0.74),
        Offset(0.14, 0.5),
        Offset(0.22, 0.26),
        Offset(0.5, 0.08),
      ],
    ],
    'P': <List<Offset>>[
      <Offset>[Offset(0.28, 0.08), Offset(0.28, 0.5), Offset(0.28, 0.92)],
      <Offset>[
        Offset(0.28, 0.08),
        Offset(0.62, 0.18),
        Offset(0.62, 0.42),
        Offset(0.28, 0.5),
      ],
    ],
    'Q': <List<Offset>>[
      <Offset>[
        Offset(0.5, 0.08),
        Offset(0.78, 0.26),
        Offset(0.86, 0.5),
        Offset(0.78, 0.74),
        Offset(0.5, 0.92),
        Offset(0.22, 0.74),
        Offset(0.14, 0.5),
        Offset(0.22, 0.26),
        Offset(0.5, 0.08),
      ],
      <Offset>[Offset(0.58, 0.66), Offset(0.86, 0.94)],
    ],
    'R': <List<Offset>>[
      <Offset>[Offset(0.28, 0.08), Offset(0.28, 0.5), Offset(0.28, 0.92)],
      <Offset>[
        Offset(0.28, 0.08),
        Offset(0.62, 0.18),
        Offset(0.62, 0.42),
        Offset(0.28, 0.5),
      ],
      <Offset>[Offset(0.42, 0.5), Offset(0.72, 0.92)],
    ],
    'S': <List<Offset>>[
      <Offset>[
        Offset(0.78, 0.22),
        Offset(0.56, 0.1),
        Offset(0.34, 0.14),
        Offset(0.26, 0.32),
        Offset(0.4, 0.48),
        Offset(0.62, 0.56),
        Offset(0.74, 0.72),
        Offset(0.62, 0.88),
        Offset(0.38, 0.92),
        Offset(0.22, 0.8),
      ],
    ],
    'T': <List<Offset>>[
      <Offset>[Offset(0.14, 0.12), Offset(0.5, 0.12), Offset(0.86, 0.12)],
      <Offset>[Offset(0.5, 0.12), Offset(0.5, 0.5), Offset(0.5, 0.92)],
    ],
    'U': <List<Offset>>[
      <Offset>[
        Offset(0.2, 0.08),
        Offset(0.2, 0.55),
        Offset(0.3, 0.82),
        Offset(0.5, 0.9),
        Offset(0.7, 0.82),
        Offset(0.8, 0.55),
        Offset(0.8, 0.08),
      ],
    ],
    'V': <List<Offset>>[
      <Offset>[
        Offset(0.15, 0.08),
        Offset(0.32, 0.45),
        Offset(0.5, 0.92),
        Offset(0.68, 0.45),
        Offset(0.85, 0.08),
      ],
    ],
    'W': <List<Offset>>[
      <Offset>[
        Offset(0.12, 0.08),
        Offset(0.28, 0.92),
        Offset(0.5, 0.42),
        Offset(0.72, 0.92),
        Offset(0.88, 0.08),
      ],
    ],
    'X': <List<Offset>>[
      <Offset>[Offset(0.2, 0.08), Offset(0.5, 0.5), Offset(0.8, 0.92)],
      <Offset>[Offset(0.8, 0.08), Offset(0.5, 0.5), Offset(0.2, 0.92)],
    ],
    'Y': <List<Offset>>[
      <Offset>[Offset(0.2, 0.08), Offset(0.5, 0.52), Offset(0.8, 0.08)],
      <Offset>[Offset(0.5, 0.52), Offset(0.5, 0.92)],
    ],
    'Z': <List<Offset>>[
      <Offset>[
        Offset(0.22, 0.1),
        Offset(0.78, 0.1),
        Offset(0.22, 0.92),
        Offset(0.78, 0.92),
      ],
    ],
  };

  @override
  LetterTraceState build() => _at(0);

  /// Builds a fresh state for the letter at sequence position [index]
  /// (wrapping the alphabet so play never dead-ends).
  LetterTraceState _at(int index) {
    final int i = index % _alphabet.length;
    final String letter = _alphabet[i];
    final List<List<Offset>> strokes = _letters[letter]!;
    return LetterTraceState(
      letterIndex: i,
      letter: letter,
      strokes: strokes,
      dots: _flatten(strokes),
    );
  }

  /// Flattens the letter's strokes into a single ordered list of unique touch
  /// targets (shared stroke endpoints collapse to one dot).
  static List<Offset> _flatten(List<List<Offset>> strokes) {
    final List<Offset> dots = <Offset>[];
    for (final List<Offset> stroke in strokes) {
      for (final Offset p in stroke) {
        if (!dots.contains(p)) dots.add(p);
      }
    }
    return dots;
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
    // A soft pop each time the finger lights up a new guide dot.
    if (next != null) ref.read(audioServiceProvider).sfx(Sfx.pop);
  }

  /// Called when the finger lifts; inserts a sentinel to break the path.
  void liftPen() {
    if (state.drawnPoints.isNotEmpty) {
      state = state.copyWith(
        drawnPoints: <Offset>[...state.drawnPoints, const Offset(-1, -1)],
      );
    }
  }

  /// Advances to the next letter in the alphabet (A→B→…→Z→A). Called when the
  /// child taps "Again!" after finishing the current letter.
  void reset() => state = _at(state.letterIndex + 1);
}

final letterTraceProvider =
    NotifierProvider<LetterTraceViewModel, LetterTraceState>(
      LetterTraceViewModel.new,
    );
