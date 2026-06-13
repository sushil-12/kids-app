import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/coloring_page.dart';

/// Immutable canvas state. Held in a Notifier (MVVM view-model layer).
class CanvasState {
  const CanvasState({
    this.strokes = const <ColorStroke>[],
    this.activeStroke,
    this.selectedColor = AppColors.coral,
    this.brushWidth = 18,
  });

  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;
  final Color selectedColor;
  final double brushWidth;

  bool get canUndo => strokes.isNotEmpty;

  CanvasState copyWith({
    List<ColorStroke>? strokes,
    ColorStroke? activeStroke,
    bool clearActive = false,
    Color? selectedColor,
    double? brushWidth,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      activeStroke: clearActive ? null : (activeStroke ?? this.activeStroke),
      selectedColor: selectedColor ?? this.selectedColor,
      brushWidth: brushWidth ?? this.brushWidth,
    );
  }
}

/// View-model: owns canvas state and exposes intent methods to the view.
/// `.family` keys the state by page id so each page keeps its own work.
class CanvasViewModel extends FamilyNotifier<CanvasState, String> {
  static const int _maxUndo = 10;

  @override
  CanvasState build(String pageId) => const CanvasState();

  void selectColor(Color color) => state = state.copyWith(selectedColor: color);

  void startStroke(Offset point) {
    state = state.copyWith(
      activeStroke: ColorStroke(
        color: state.selectedColor,
        width: state.brushWidth,
        points: <Offset>[point],
      ),
    );
  }

  void extendStroke(Offset point) {
    final ColorStroke? active = state.activeStroke;
    if (active == null) return;
    state = state.copyWith(
      activeStroke: active.copyWith(points: <Offset>[...active.points, point]),
    );
  }

  void endStroke() {
    final ColorStroke? active = state.activeStroke;
    if (active == null) return;
    final List<ColorStroke> next = <ColorStroke>[...state.strokes, active];
    // Cap the undo history so memory stays bounded.
    final List<ColorStroke> capped =
        next.length > _maxUndo ? next.sublist(next.length - _maxUndo) : next;
    state = state.copyWith(strokes: capped, clearActive: true);
  }

  void undo() {
    if (!state.canUndo) return;
    state = state.copyWith(strokes: state.strokes.sublist(0, state.strokes.length - 1));
  }
}

final canvasViewModelProvider =
    NotifierProvider.family<CanvasViewModel, CanvasState, String>(CanvasViewModel.new);
