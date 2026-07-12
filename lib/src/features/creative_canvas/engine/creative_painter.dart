import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../coloring/data/coloring_page.dart';
import '../../coloring/data/coloring_template.dart';

/// Renders the Creative Canvas: a white page, an optional faint trace guide
/// underneath, then the child's freehand strokes on top.
///
/// Performance (mirrors [ColoringPainter]):
/// * Everything draws under a single canvas transform (logical 100×100 space).
/// * `shouldRepaint` uses cheap identity/length checks; wrap the call site in a
///   `RepaintBoundary`.
class CreativePainter extends CustomPainter {
  CreativePainter({
    required this.viewBox,
    required this.guidePaths,
    required this.strokes,
    this.activeStroke,
    this.showGuide = true,
    super.repaint,
  });

  /// Logical coordinate space the guide paths are authored in.
  final double viewBox;

  /// Faint outline to trace; empty for free-draw.
  final List<Path> guidePaths;
  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;

  /// When false (free-draw, or after capture) the guide is not drawn.
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final CanvasFit fit = CanvasFit.of(size, viewBox);
    canvas.save();
    canvas.translate(fit.offset.dx, fit.offset.dy);
    canvas.scale(fit.scale);

    // 1. Faint trace guide, drawn under the strokes so the child draws over it.
    if (showGuide && guidePaths.isNotEmpty) {
      final Paint guide = Paint()
        ..color = AppColors.dark.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      for (final Path path in guidePaths) {
        canvas.drawPath(path, guide);
      }
    }

    // 2. Freehand strokes (brush + white "eraser" strokes), oldest first.
    for (final ColorStroke stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    final ColorStroke? active = activeStroke;
    if (active != null) _drawStroke(canvas, active);

    canvas.restore();
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
      canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
      return;
    }
    final Path path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CreativePainter old) {
    return old.showGuide != showGuide ||
        old.guidePaths != guidePaths ||
        old.strokes != strokes ||
        old.activeStroke?.points.length != activeStroke?.points.length ||
        old.activeStroke?.color != activeStroke?.color;
  }
}
