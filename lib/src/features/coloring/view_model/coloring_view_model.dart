import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/coloring_page.dart';
import '../data/coloring_template.dart';
import '../data/coloring_templates.dart';

/// The active tool. Fill is the hero interaction for young children.
enum CanvasTool { fill, brush, eraser }

/// One reversible edit, so a single Undo button covers fills and strokes.
sealed class CanvasAction {
  const CanvasAction();
}

class FillAction extends CanvasAction {
  const FillAction(this.regionId, this.previous);
  final String regionId;
  final Color? previous;
}

class StrokeAction extends CanvasAction {
  const StrokeAction();
}

/// Immutable canvas state (MVVM view-model layer).
@immutable
class CanvasState {
  const CanvasState({
    required this.template,
    this.fills = const <String, Color>{},
    this.strokes = const <ColorStroke>[],
    this.activeStroke,
    this.selectedColor = AppColors.coral,
    this.tool = CanvasTool.fill,
    this.history = const <CanvasAction>[],
  });

  final ColoringTemplate template;
  final Map<String, Color> fills;
  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;
  final Color selectedColor;
  final CanvasTool tool;
  final List<CanvasAction> history;

  bool get canUndo => history.isNotEmpty;

  /// How much of the picture has been colored, 0..1 (for the celebration gate).
  double get progress {
    final int total = template.regions.length;
    if (total == 0) return 0;
    return fills.length / total;
  }

  CanvasState copyWith({
    Map<String, Color>? fills,
    List<ColorStroke>? strokes,
    ColorStroke? activeStroke,
    bool clearActive = false,
    Color? selectedColor,
    CanvasTool? tool,
    List<CanvasAction>? history,
  }) {
    return CanvasState(
      template: template,
      fills: fills ?? this.fills,
      strokes: strokes ?? this.strokes,
      activeStroke: clearActive ? null : (activeStroke ?? this.activeStroke),
      selectedColor: selectedColor ?? this.selectedColor,
      tool: tool ?? this.tool,
      history: history ?? this.history,
    );
  }
}

/// Owns canvas state and exposes intent methods to the view.
/// `.family` keys state by template id so each picture keeps its own work.
class CanvasViewModel extends FamilyNotifier<CanvasState, String> {
  static const int _maxHistory = 20;
  static const double _brushWidth = 3.5; // logical units

  @override
  CanvasState build(String templateId) {
    final ColoringTemplate template =
        templateById(templateId) ?? kColoringTemplates.first;
    return CanvasState(template: template);
  }

  AudioService get _audio => ref.read(audioServiceProvider);

  void selectColor(Color color) {
    state = state.copyWith(selectedColor: color);
    // Say the color name so children connect the swatch to the spoken word.
    _audio.sfx(Sfx.pop);
    unawaited(_audio.speakColor(color));
  }

  void selectTool(CanvasTool tool) {
    state = state.copyWith(tool: tool);
    _audio.sfx(Sfx.tap);
  }

  /// Tap handler for Fill / Eraser tools.
  void tapAt(Offset logicalPoint) {
    final String? regionId = state.template.hitTest(logicalPoint);
    if (regionId == null) return;

    final Map<String, Color> next = Map<String, Color>.of(state.fills);
    final Color? previous = next[regionId];

    if (state.tool == CanvasTool.eraser) {
      next.remove(regionId);
      _audio.sfx(Sfx.tap);
    } else {
      next[regionId] = state.selectedColor;
      // Satisfying "plop" + the color name on every fill.
      _audio.sfx(Sfx.plop);
      unawaited(_audio.speakColor(state.selectedColor));
    }

    state = state.copyWith(
      fills: next,
      history: _push(FillAction(regionId, previous)),
    );
  }

  void startStroke(Offset logicalPoint) {
    if (state.tool != CanvasTool.brush) return;
    state = state.copyWith(
      activeStroke: ColorStroke(
        color: state.selectedColor,
        width: _brushWidth,
        points: <Offset>[logicalPoint],
      ),
    );
  }

  void extendStroke(Offset logicalPoint) {
    final ColorStroke? active = state.activeStroke;
    if (active == null) return;
    state = state.copyWith(
      activeStroke:
          active.copyWith(points: <Offset>[...active.points, logicalPoint]),
    );
  }

  void endStroke() {
    final ColorStroke? active = state.activeStroke;
    if (active == null) return;
    state = state.copyWith(
      strokes: <ColorStroke>[...state.strokes, active],
      clearActive: true,
      history: _push(const StrokeAction()),
    );
  }

  void undo() {
    if (!state.canUndo) return;
    final CanvasAction last = state.history.last;
    final List<CanvasAction> history =
        state.history.sublist(0, state.history.length - 1);

    switch (last) {
      case FillAction(:final String regionId, :final Color? previous):
        final Map<String, Color> next = Map<String, Color>.of(state.fills);
        if (previous == null) {
          next.remove(regionId);
        } else {
          next[regionId] = previous;
        }
        state = state.copyWith(fills: next, history: history);
      case StrokeAction():
        state = state.copyWith(
          strokes: state.strokes.sublist(0, state.strokes.length - 1),
          history: history,
        );
    }
  }

  List<CanvasAction> _push(CanvasAction action) {
    final List<CanvasAction> next = <CanvasAction>[...state.history, action];
    return next.length > _maxHistory
        ? next.sublist(next.length - _maxHistory)
        : next;
  }
}

final canvasViewModelProvider =
    NotifierProvider.family<CanvasViewModel, CanvasState, String>(
  CanvasViewModel.new,
);
