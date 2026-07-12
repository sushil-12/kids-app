import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/feature_flags.dart';
import '../../../adaptive/data/difficulty.dart';
import '../../../adaptive/view_model/adaptive_view_model.dart';

/// Immutable state for Count & Tap.
@immutable
class CountTapState {
  const CountTapState({
    required this.target,
    required this.itemCount,
    required this.tapped,
    required this.round,
    this.completed = false,
  });

  /// How many apples the child should tap this round.
  final int target;

  /// How many apples are on screen (≥ target).
  final int itemCount;

  /// Indices already tapped.
  final Set<int> tapped;

  /// 1-based current round.
  final int round;
  final bool completed;

  static const int totalRounds = 5;

  bool get roundComplete => tapped.length >= target;
  bool get isComplete => completed;
  int get roundsDone => completed ? totalRounds : round - 1;

  CountTapState copyWith({Set<int>? tapped, bool? completed}) => CountTapState(
        target: target,
        itemCount: itemCount,
        tapped: tapped ?? this.tapped,
        round: round,
        completed: completed ?? this.completed,
      );
}

/// Owns Count & Tap state across five rounds. Once [target] apples are tapped
/// the round is done; extra apples simply stop responding (no fail state).
class CountTapViewModel extends Notifier<CountTapState> {
  final math.Random _rng = math.Random();

  @override
  CountTapState build() => _round(1);

  /// The difficulty for the next round. When adaptive difficulty is off this is
  /// always [DifficultyLevel.medium], i.e. the original 1..5 behaviour.
  DifficultyLevel _difficulty() {
    if (!ref.read(featureFlagsProvider).adaptiveDifficulty) {
      return DifficultyLevel.medium;
    }
    return ref.read(adaptiveProvider.notifier).difficultyFor(GameId.countTap);
  }

  CountTapState _round(int round) {
    // (min target, max target, max decoys) per difficulty. Higher counts and
    // more decoys make the "how many?" question harder, never unfair.
    final (int minTarget, int maxTarget, int maxDecoys) = switch (_difficulty()) {
      DifficultyLevel.easy => (1, 3, 2),
      DifficultyLevel.medium => (1, 5, 4),
      DifficultyLevel.hard => (3, 7, 5),
    };
    final int target = minTarget + _rng.nextInt(maxTarget - minTarget + 1);
    final int extra = 1 + _rng.nextInt(maxDecoys); // a few decoys
    final int itemCount = math.min(target + extra, 9);
    return CountTapState(
      target: target,
      itemCount: itemCount,
      tapped: <int>{},
      round: round,
    );
  }

  /// Taps apple [index], ignoring taps once the target is reached.
  void tapItem(int index) {
    if (state.completed || state.roundComplete || state.tapped.contains(index)) {
      return;
    }
    final Set<int> tapped = <int>{...state.tapped, index};
    state = state.copyWith(tapped: tapped);
    // Count out loud as each apple is tapped: "1… 2… 3!"
    final AudioService audio = ref.read(audioServiceProvider);
    audio.sfx(Sfx.chime);
    unawaited(audio.speakNumber(tapped.length));
  }

  /// Advances to the next round, or finishes after the last one. Counting has no
  /// "wrong tap", so each finished round is a clean success signal that lets the
  /// counts grow as the child keeps succeeding.
  void nextRound() {
    if (ref.read(featureFlagsProvider).adaptiveDifficulty) {
      ref
          .read(adaptiveProvider.notifier)
          .recordRound(GameId.countTap, struggled: false);
    }
    if (state.round >= CountTapState.totalRounds) {
      state = state.copyWith(completed: true);
    } else {
      state = _round(state.round + 1);
    }
  }

  void reset() => state = _round(1);
}

final countTapProvider =
    NotifierProvider<CountTapViewModel, CountTapState>(CountTapViewModel.new);
