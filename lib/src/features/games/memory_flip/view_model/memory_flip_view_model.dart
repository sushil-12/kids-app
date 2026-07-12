import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/audio_service.dart';

/// One card in the grid. [symbol] is shared by its pair.
@immutable
class MemoryCard {
  const MemoryCard({
    required this.symbol,
    this.faceUp = false,
    this.matched = false,
  });

  final String symbol;
  final bool faceUp;
  final bool matched;

  MemoryCard copyWith({bool? faceUp, bool? matched}) => MemoryCard(
        symbol: symbol,
        faceUp: faceUp ?? this.faceUp,
        matched: matched ?? this.matched,
      );
}

/// Immutable state for Memory Flip.
@immutable
class MemoryFlipState {
  const MemoryFlipState({
    required this.cards,
    this.firstIndex,
    this.mismatch = const <int>[],
  });

  final List<MemoryCard> cards;

  /// Index of the lone face-up unmatched card, if any.
  final int? firstIndex;

  /// The two indices currently shown as a wrong guess, awaiting flip-back.
  final List<int> mismatch;

  bool get busy => mismatch.isNotEmpty;
  int get matchedPairs => cards.where((MemoryCard c) => c.matched).length ~/ 2;
  int get totalPairs => cards.length ~/ 2;
  bool get isComplete => cards.isNotEmpty && cards.every((MemoryCard c) => c.matched);

  MemoryFlipState copyWith({
    List<MemoryCard>? cards,
    int? firstIndex,
    bool clearFirst = false,
    List<int>? mismatch,
  }) =>
      MemoryFlipState(
        cards: cards ?? this.cards,
        firstIndex: clearFirst ? null : (firstIndex ?? this.firstIndex),
        mismatch: mismatch ?? this.mismatch,
      );
}

/// Owns Memory Flip state. Mismatched pairs are flipped back by the view after
/// a short pause via [hideMismatch] — there is no "wrong" penalty.
class MemoryFlipViewModel extends Notifier<MemoryFlipState> {
  static const List<String> _symbols = <String>['🦊', '🐼', '🐸', '🦋'];

  @override
  MemoryFlipState build() => _newGame();

  MemoryFlipState _newGame() {
    final List<MemoryCard> cards = <MemoryCard>[
      for (final String s in _symbols) ...<MemoryCard>[
        MemoryCard(symbol: s),
        MemoryCard(symbol: s),
      ],
    ]..shuffle(math.Random());
    return MemoryFlipState(cards: cards);
  }

  /// Flips card [index] face-up and resolves matches.
  void flip(int index) {
    if (state.busy) return;
    final MemoryCard card = state.cards[index];
    if (card.faceUp || card.matched) return;

    final List<MemoryCard> cards = List<MemoryCard>.of(state.cards);
    cards[index] = card.copyWith(faceUp: true);

    final AudioService audio = ref.read(audioServiceProvider);
    audio.sfx(Sfx.flip); // every flip gets a satisfying turn sound

    final int? first = state.firstIndex;
    if (first == null) {
      state = state.copyWith(cards: cards, firstIndex: index);
      return;
    }

    if (cards[first].symbol == card.symbol) {
      cards[first] = cards[first].copyWith(matched: true);
      cards[index] = cards[index].copyWith(matched: true);
      state = state.copyWith(cards: cards, clearFirst: true);
      audio.sfx(Sfx.chime); // a pair! cheerful confirm
    } else {
      // Show both, then the view calls [hideMismatch] after a beat.
      state = state.copyWith(
        cards: cards,
        clearFirst: true,
        mismatch: <int>[first, index],
      );
    }
  }

  /// Flips the mismatched pair back down.
  void hideMismatch() {
    if (state.mismatch.isEmpty) return;
    final List<MemoryCard> cards = List<MemoryCard>.of(state.cards);
    for (final int i in state.mismatch) {
      cards[i] = cards[i].copyWith(faceUp: false);
    }
    state = state.copyWith(cards: cards, mismatch: <int>[]);
  }

  void reset() => state = _newGame();
}

final memoryFlipProvider =
    NotifierProvider<MemoryFlipViewModel, MemoryFlipState>(MemoryFlipViewModel.new);
