import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../coloring/data/coloring_page.dart';
import '../data/creative_guide.dart';

/// The active drawing tool on the Creative Canvas.
enum CreativeTool { brush, eraser }

/// Brush thicknesses (logical viewBox units), small → large.
enum CreativeBrush { thin, medium, thick }

extension CreativeBrushWidth on CreativeBrush {
  double get width => switch (this) {
        CreativeBrush.thin => 2.5,
        CreativeBrush.medium => 4.5,
        CreativeBrush.thick => 7.5,
      };
}

/// Immutable Creative-Canvas state (MVVM view-model layer). Mirrors the
/// Coloring Studio's [CanvasState] but freehand-only — there are no regions.
@immutable
class CreativeState {
  const CreativeState({
    required this.guide,
    required this.mode,
    this.strokes = const <ColorStroke>[],
    this.activeStroke,
    this.selectedColor = AppColors.coral,
    this.brush = CreativeBrush.medium,
    this.tool = CreativeTool.brush,
    this.history = const <ColorStroke>[],
  });

  /// The trace guide, or null for a blank free-draw page.
  final TraceGuide? guide;
  final CreativeMode mode;
  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;
  final Color selectedColor;
  final CreativeBrush brush;
  final CreativeTool tool;

  /// Undo stack — one entry per completed stroke (capped). Freehand-only, so a
  /// plain stroke list is enough; no sealed action union is needed here.
  final List<ColorStroke> history;

  bool get canUndo => strokes.isNotEmpty;
  bool get hasDrawn => strokes.isNotEmpty;
  List<Path> get guidePaths => guide?.guidePaths ?? const <Path>[];
  double get viewBox => guide?.viewBox ?? 100;

  CreativeState copyWith({
    List<ColorStroke>? strokes,
    ColorStroke? activeStroke,
    bool clearActive = false,
    Color? selectedColor,
    CreativeBrush? brush,
    CreativeTool? tool,
    List<ColorStroke>? history,
  }) {
    return CreativeState(
      guide: guide,
      mode: mode,
      strokes: strokes ?? this.strokes,
      activeStroke: clearActive ? null : (activeStroke ?? this.activeStroke),
      selectedColor: selectedColor ?? this.selectedColor,
      brush: brush ?? this.brush,
      tool: tool ?? this.tool,
      history: history ?? this.history,
    );
  }
}

/// Owns Creative-Canvas state and exposes intent methods to the view.
/// `.family` keys state by guide id (or [kFreeDrawId]) so each guide keeps its
/// own in-progress drawing.
class CreativeCanvasViewModel extends FamilyNotifier<CreativeState, String> {
  @override
  CreativeState build(String guideId) {
    final TraceGuide? guide = guideById(guideId);
    return CreativeState(
      guide: guide,
      mode: guide?.mode ?? CreativeMode.freeDraw,
    );
  }

  AudioService get _audio => ref.read(audioServiceProvider);

  void selectColor(Color color) {
    // Picking a color also switches back to the brush — you can't paint with
    // a color while the eraser is selected.
    state = state.copyWith(selectedColor: color, tool: CreativeTool.brush);
    _audio.sfx(Sfx.pop);
    unawaited(_audio.speakColor(color));
  }

  void selectBrush(CreativeBrush brush) {
    state = state.copyWith(brush: brush);
    _audio.sfx(Sfx.tap);
  }

  void selectTool(CreativeTool tool) {
    state = state.copyWith(tool: tool);
    _audio.sfx(Sfx.tap);
  }

  void startStroke(Offset logicalPoint) {
    // The eraser is just a white stroke painted over the white page.
    final Color color =
        state.tool == CreativeTool.eraser ? Colors.white : state.selectedColor;
    // A slightly wider eraser feels more forgiving for small hands.
    final double width = state.tool == CreativeTool.eraser
        ? state.brush.width * 1.6
        : state.brush.width;
    state = state.copyWith(
      activeStroke: ColorStroke(
        color: color,
        width: width,
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
    );
  }

  void undo() {
    if (!state.canUndo) return;
    state = state.copyWith(
      strokes: state.strokes.sublist(0, state.strokes.length - 1),
    );
  }

  /// Wipes the page back to blank (the trace guide stays). Used by "Again!".
  void clear() {
    if (!state.hasDrawn && state.activeStroke == null) return;
    state = state.copyWith(
      strokes: const <ColorStroke>[],
      clearActive: true,
    );
    _audio.sfx(Sfx.tap);
  }
}

final creativeCanvasViewModelProvider =
    NotifierProvider.family<CreativeCanvasViewModel, CreativeState, String>(
  CreativeCanvasViewModel.new,
);
