import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/by_number_palette.dart';
import '../data/coloring_template.dart';

/// Renders a Color-by-Number picture: solved regions in their final color,
/// unsolved regions in soft grey with their number printed in the middle.
/// Regions matching the currently selected number get a faint tint so young
/// children can see where to tap next.
///
/// Draws under one canvas transform (logical viewBox space) and uses cheap
/// `shouldRepaint` identity checks, like [ColoringPainter]; wrap in a
/// `RepaintBoundary`.
class ColorByNumberPainter extends CustomPainter {
  ColorByNumberPainter({
    required this.template,
    required this.fills,
    required this.selectedNumber,
    this.outlineWidth = 1.8,
  });

  final ColoringTemplate template;
  final Map<String, Color> fills;
  final int selectedNumber;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final CanvasFit fit = CanvasFit.of(size, template.viewBox);
    canvas.save();
    canvas.translate(fit.offset.dx, fit.offset.dy);
    canvas.scale(fit.scale);

    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Region fills: solved → final color; unsolved → grey, faintly tinted
    //    when they match the selected number to hint where to tap.
    for (final ColorRegion region in template.regions) {
      final Color? solved = fills[region.id];
      if (solved != null) {
        fill.color = solved;
      } else {
        final int? target = template.byNumber[region.id];
        final Color? hint = target == null ? null : byNumberColor(target);
        fill.color =
            (target != null && target == selectedNumber && hint != null)
                ? hint.withValues(alpha: 0.22)
                : AppColors.grey;
      }
      canvas.drawPath(region.path, fill);
    }

    // 2. Black line art.
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

    // 3. Solid-black details.
    final Paint detail = Paint()
      ..color = AppColors.dark
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final Path path in template.details) {
      canvas.drawPath(path, detail);
    }

    // 4. Numbers on every still-unsolved numbered region.
    for (final ColorRegion region in template.regions) {
      if (fills.containsKey(region.id)) continue;
      final int? number = template.byNumber[region.id];
      if (number == null) continue;
      _drawNumber(canvas, number, region.path.getBounds().center);
    }

    canvas.restore();
  }

  void _drawNumber(Canvas canvas, int number, Offset center) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          // Logical units (viewBox is 100), so this stays crisp at any size.
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(ColorByNumberPainter old) =>
      old.template.id != template.id ||
      old.fills != fills ||
      old.selectedNumber != selectedNumber;
}
