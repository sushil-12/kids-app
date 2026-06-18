import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/by_number_palette.dart';
import '../data/coloring_template.dart';
import '../data/coloring_templates.dart';

/// Immutable state for one Color-by-Number picture.
@immutable
class ByNumberState {
  const ByNumberState({
    required this.template,
    required this.selectedNumber,
    required this.fills,
    this.wrongNudge = 0,
  });

  final ColoringTemplate template;

  /// The 1-based palette number the child is currently painting with.
  final int selectedNumber;

  /// Region id → the color it was correctly filled with.
  final Map<String, Color> fills;

  /// Increments on each mismatched tap so the view can play a gentle wobble.
  final int wrongNudge;

  /// Total regions that carry a number (the ones that must be filled).
  int get totalRegions => template.byNumber.length;
  int get filledRegions => fills.length;
  bool get isComplete => totalRegions > 0 && filledRegions >= totalRegions;

  ByNumberState copyWith({
    int? selectedNumber,
    Map<String, Color>? fills,
    int? wrongNudge,
  }) =>
      ByNumberState(
        template: template,
        selectedNumber: selectedNumber ?? this.selectedNumber,
        fills: fills ?? this.fills,
        wrongNudge: wrongNudge ?? this.wrongNudge,
      );
}

/// Owns one Color-by-Number picture, keyed by template id. The child selects a
/// number then taps regions: a tap whose region number matches the selection
/// fills it with the correct color; a mismatched tap only nudges (no fail
/// state, House Rule §5). Filling the last numbered region completes it.
class ByNumberViewModel extends FamilyNotifier<ByNumberState, String> {
  @override
  ByNumberState build(String templateId) {
    final ColoringTemplate template =
        templateById(templateId) ?? kColoringTemplates.first;
    return ByNumberState(
      template: template,
      selectedNumber: 1,
      fills: const <String, Color>{},
    );
  }

  /// Selects the active palette number (1-based).
  void selectNumber(int number) {
    if (number == state.selectedNumber) return;
    state = state.copyWith(selectedNumber: number);
  }

  /// Handles a tap on [regionId]. Fills it only when the selected number matches
  /// the region's target number; otherwise records a gentle nudge.
  void tapRegion(String regionId) {
    if (state.fills.containsKey(regionId)) return; // already done
    final int? target = state.template.byNumber[regionId];
    if (target == null) return; // region is not part of the puzzle

    if (target == state.selectedNumber) {
      final Color? color = byNumberColor(target);
      if (color == null) return;
      state = state.copyWith(
        fills: <String, Color>{...state.fills, regionId: color},
      );
    } else {
      state = state.copyWith(wrongNudge: state.wrongNudge + 1);
    }
  }

  void reset() => state = build(state.template.id);
}

final byNumberProvider =
    NotifierProvider.family<ByNumberViewModel, ByNumberState, String>(
  ByNumberViewModel.new,
);
