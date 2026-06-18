import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// A named color used by Color Match. The name resolves through l10n so the
/// instruction ("Tap everything red!") and the tiles always agree.
enum MatchColor { red, orange, yellow, green, blue, purple, pink }

extension MatchColorX on MatchColor {
  Color get color => switch (this) {
        MatchColor.red => AppColors.coral,
        MatchColor.orange => AppColors.orange,
        MatchColor.yellow => AppColors.yellow,
        MatchColor.green => AppColors.green,
        MatchColor.blue => AppColors.blue,
        MatchColor.purple => AppColors.purple,
        MatchColor.pink => AppColors.pink,
      };

  String label(AppLocalizations l10n) => switch (this) {
        MatchColor.red => l10n.colorRed,
        MatchColor.orange => l10n.colorOrange,
        MatchColor.yellow => l10n.colorYellow,
        MatchColor.green => l10n.colorGreen,
        MatchColor.blue => l10n.colorBlue,
        MatchColor.purple => l10n.colorPurple,
        MatchColor.pink => l10n.colorPink,
      };
}

/// Immutable state for Color Match.
@immutable
class ColorMatchState {
  const ColorMatchState({
    required this.items,
    required this.target,
    required this.found,
    required this.round,
    this.completed = false,
  });

  /// The colored tiles for the current round.
  final List<MatchColor> items;

  /// The color the child must tap.
  final MatchColor target;

  /// Indices of correctly tapped (matching) tiles.
  final Set<int> found;

  /// 1-based current round.
  final int round;
  final bool completed;

  static const int totalRounds = 3;

  int get matchingTotal => items.where((MatchColor c) => c == target).length;
  bool get roundComplete => found.length >= matchingTotal;
  bool get isComplete => completed;
  int get roundsDone => completed ? totalRounds : round - 1;

  ColorMatchState copyWith({Set<int>? found, bool? completed}) => ColorMatchState(
        items: items,
        target: target,
        found: found ?? this.found,
        round: round,
        completed: completed ?? this.completed,
      );
}

/// Owns Color Match state. Tapping a non-matching tile is handled in the view
/// (gentle wobble) and never reaches here — no fail state.
class ColorMatchViewModel extends Notifier<ColorMatchState> {
  final math.Random _rng = math.Random();

  @override
  ColorMatchState build() => _round(1);

  ColorMatchState _round(int round) {
    final List<MatchColor> palette = List<MatchColor>.of(MatchColor.values)..shuffle(_rng);
    final MatchColor target = palette.first;

    // 2–3 matching tiles, the rest drawn from other colors. 9 tiles total.
    final int matching = 2 + _rng.nextInt(2);
    final List<MatchColor> others = palette.skip(1).toList();
    final List<MatchColor> items = <MatchColor>[
      for (int i = 0; i < matching; i++) target,
      for (int i = 0; i < 9 - matching; i++) others[_rng.nextInt(others.length)],
    ]..shuffle(_rng);

    return ColorMatchState(items: items, target: target, found: <int>{}, round: round);
  }

  /// Records a correct tap on tile [index].
  void tapMatch(int index) {
    if (state.completed || state.found.contains(index)) return;
    if (state.items[index] != state.target) return;
    state = state.copyWith(found: <int>{...state.found, index});
  }

  /// Advances to the next round, or finishes the game after the last one.
  void nextRound() {
    if (state.round >= ColorMatchState.totalRounds) {
      state = state.copyWith(completed: true);
    } else {
      state = _round(state.round + 1);
    }
  }

  void reset() => state = _round(1);
}

final colorMatchProvider =
    NotifierProvider<ColorMatchViewModel, ColorMatchState>(ColorMatchViewModel.new);
