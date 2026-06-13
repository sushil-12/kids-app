import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/coloring_page.dart';

/// Renders all committed strokes plus the in-progress stroke.
///
/// Performance notes (per Flutter perf best practices):
/// * `shouldRepaint` compares the stroke list identity + active stroke length,
///   so we only repaint when something actually changed.
/// * Strokes are drawn as a single `Path` per stroke to minimise draw calls.
/// * The line-art overlay is painted last so fills always sit *under* the
///   outline — this is what creates the "stay in the lines" look.
/// * Keep this widget wrapped in a `RepaintBoundary` at the call site so
///   canvas repaints never bubble up into the rest of the tree.
class ColoringPainter extends CustomPainter {
  ColoringPainter({
    required this.strokes,
    required this.activeStroke,
    required this.repaint,
  }) : super(repaint: repaint);

  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;
  final Listenable repaint;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ColorStroke stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    final ColorStroke? active = activeStroke;
    if (active != null) _drawStroke(canvas, active);
  }

  void _drawStroke(Canvas canvas, ColorStroke stroke) {
    if (stroke.points.isEmpty) return;

    final Paint paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      // A single tap = a dot.
      canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
      return;
    }

    final Path path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ColoringPainter old) {
    // Cheap identity checks — avoids deep list comparison every frame.
    return old.strokes != strokes ||
        old.activeStroke?.points.length != activeStroke?.points.length ||
        old.activeStroke?.color != activeStroke?.color;
  }
}
