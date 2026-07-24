import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The shapes used by Shape Sorter. Kept here so the game's data, painter and
/// view all agree on one enum.
enum ShapeKind { circle, square, triangle, star, heart }

/// Draws a single [ShapeKind] — either solid ([outlined] = false) or as a
/// hollow target outline (used for the empty holes a child drags shapes into).
class ShapeView extends StatelessWidget {
  const ShapeView({
    required this.kind,
    required this.color,
    this.size = 80,
    this.outlined = false,
    super.key,
  });

  final ShapeKind kind;
  final Color color;
  final double size;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: ShapePainter(kind: kind, color: color, outlined: outlined),
      ),
    );
  }
}

/// Paints a [ShapeKind] inside its box. Cheap [shouldRepaint] — identity only.
class ShapePainter extends CustomPainter {
  const ShapePainter({
    required this.kind,
    required this.color,
    this.outlined = false,
  });

  final ShapeKind kind;
  final Color color;
  final bool outlined;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = pathFor(kind, size);
    if (outlined) {
      final Paint fill = Paint()..color = color.withValues(alpha: 0.12);
      final Paint stroke = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round;
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, stroke);
    } else {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  /// Builds the geometry for [kind], padded inside [size].
  static Path pathFor(ShapeKind kind, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double pad = w * 0.1;
    final Rect box = Rect.fromLTRB(pad, pad, w - pad, h - pad);
    final Offset c = box.center;
    final double r = box.shortestSide / 2;

    switch (kind) {
      case ShapeKind.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case ShapeKind.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(box, const Radius.circular(10)));
      case ShapeKind.triangle:
        return Path()
          ..moveTo(c.dx, box.top)
          ..lineTo(box.right, box.bottom)
          ..lineTo(box.left, box.bottom)
          ..close();
      case ShapeKind.star:
        return _star(c, r);
      case ShapeKind.heart:
        return _heart(box);
    }
  }

  static Path _star(Offset c, double r) {
    final Path path = Path();
    const int points = 5;
    final double inner = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? r : inner;
      final double angle = -math.pi / 2 + i * math.pi / points;
      final Offset p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _heart(Rect box) {
    final double w = box.width;
    final double h = box.height;
    final Path path = Path()..moveTo(box.left + w / 2, box.bottom);
    path.cubicTo(
      box.left - w * 0.1,
      box.top + h * 0.45,
      box.left + w * 0.3,
      box.top - h * 0.05,
      box.left + w / 2,
      box.top + h * 0.28,
    );
    path.cubicTo(
      box.left + w * 0.7,
      box.top - h * 0.05,
      box.right + w * 0.1,
      box.top + h * 0.45,
      box.left + w / 2,
      box.bottom,
    );
    return path..close();
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.kind != kind || old.color != color || old.outlined != outlined;
}
