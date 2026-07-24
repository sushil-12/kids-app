import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/coloring_page.dart';
import '../data/coloring_template.dart';

/// Renders a coloring picture: region fills, then freehand strokes, then the
/// black line art on top so colors always sit *inside* the outline.
///
/// Performance (per Flutter perf best practices):
/// * Everything draws under a single canvas transform (logical viewBox space).
/// * `shouldRepaint` uses cheap identity/length checks to stay well under the
///   16ms frame budget; wrap the call site in a `RepaintBoundary`.
class ColoringPainter extends CustomPainter {
  ColoringPainter({
    required this.template,
    required this.fills,
    required this.strokes,
    this.activeStroke,
    this.outlineWidth = 1.8,
    super.repaint,
  });

  final ColoringTemplate template;
  final Map<String, Color> fills;
  final List<ColorStroke> strokes;
  final ColorStroke? activeStroke;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final CanvasFit fit = CanvasFit.of(size, template.viewBox);
    canvas.save();
    canvas.translate(fit.offset.dx, fit.offset.dy);
    canvas.scale(fit.scale);

    // 1. Region fills (default white so the picture reads as "uncolored").
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final ColorRegion region in template.regions) {
      fill.color = fills[region.id] ?? Colors.white;
      canvas.drawPath(region.path, fill);
    }

    // 2. Freehand strokes (brush).
    for (final ColorStroke stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    final ColorStroke? active = activeStroke;
    if (active != null) _drawStroke(canvas, active);

    // 3. Black line art.
    final Paint outline = Paint()
      ..color = AppColors.dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final Path path in template.outlines) {
      canvas.drawPath(path, outline);
    }

    // 4. Solid-black details (eyes, doorknob...).
    final Paint detail = Paint()
      ..color = AppColors.dark
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final Path path in template.details) {
      canvas.drawPath(path, detail);
    }

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
  bool shouldRepaint(ColoringPainter old) {
    return old.template.id != template.id ||
        old.fills != fills ||
        old.strokes != strokes ||
        old.activeStroke?.points.length != activeStroke?.points.length ||
        old.activeStroke?.color != activeStroke?.color;
  }
}
