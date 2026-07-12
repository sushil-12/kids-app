import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Which welcome slide the mascot is illustrating. Each pose keeps the same
/// body and face — only the arms and floating props change — so the
/// character reads as one consistent buddy across the intro flow.
enum WelcomePose { coloring, games, rewards }

/// Draws BrightMind Kids' onboarding mascot as flat, original vector shapes
/// (circles, rounded rects, simple bezier curves) instead of a bundled
/// image. Keeping it code-drawn avoids any licensed/stock art and matches
/// the flat, hand-built look the intro flow is going for.
///
/// Composed in a fixed 220x220 logical box, scaled to fit [Size] like
/// `BoxFit.contain`.
class MascotPainter extends CustomPainter {
  const MascotPainter({required this.pose});

  final WelcomePose pose;

  static const double _box = 220;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(size.width, size.height) / _box;
    canvas.save();
    canvas.translate(
      (size.width - _box * scale) / 2,
      (size.height - _box * scale) / 2,
    );
    canvas.scale(scale);

    switch (pose) {
      case WelcomePose.coloring:
        _paintRainbow(canvas);
        break;
      case WelcomePose.games:
        break;
      case WelcomePose.rewards:
        _paintFlame(canvas, const Offset(38, 52), 0.9);
        _paintSparkle(canvas, const Offset(192, 44), 0.8, AppColors.yellow);
        _paintSparkle(canvas, const Offset(24, 150), 0.7, AppColors.teal);
        break;
    }

    _paintGroundShadow(canvas);
    _paintBodyLayer(canvas, offset: const Offset(4, 6), color: AppColors.pinkDeep);
    _paintArms(canvas);
    _paintBodyLayer(canvas, offset: Offset.zero, color: AppColors.pink);
    _paintBellyShade(canvas);
    _paintFace(canvas);

    switch (pose) {
      case WelcomePose.coloring:
        _paintCrayon(canvas);
        _paintFlecks(canvas);
        break;
      case WelcomePose.games:
        _paintFloatingProps(canvas);
        _paintMotionDashes(canvas);
        break;
      case WelcomePose.rewards:
        _paintBadge(canvas);
        break;
    }

    canvas.restore();
  }

  // ── body ───────────────────────────────────────────────────────────────

  void _paintBodyLayer(Canvas canvas, {required Offset offset, required Color color}) {
    final Paint paint = Paint()..color = color;
    for (final _Circle c in const <_Circle>[
      _Circle(82, 68, 28),
      _Circle(108, 52, 32),
      _Circle(136, 60, 28),
      _Circle(155, 84, 24),
    ]) {
      canvas.drawCircle(Offset(c.cx, c.cy) + offset, c.r, paint);
    }
    final Rect body = const Rect.fromLTWH(64, 70, 104, 86).shift(offset);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(42)), paint);
  }

  void _paintBellyShade(Canvas canvas) {
    final Paint paint = Paint()..color = AppColors.pinkDeep.withValues(alpha: 0.3);
    canvas.drawOval(Rect.fromCenter(center: const Offset(116, 138), width: 80, height: 32), paint);
  }

  void _paintGroundShadow(Canvas canvas) {
    final Paint paint = Paint()..color = AppColors.dark.withValues(alpha: 0.1);
    canvas.drawOval(Rect.fromCenter(center: const Offset(116, 197), width: 92, height: 18), paint);
  }

  void _paintFace(Canvas canvas) {
    final Paint white = Paint()..color = Colors.white;
    final Paint pupil = Paint()..color = AppColors.dark;
    final Paint highlight = Paint()..color = Colors.white;
    final Paint blush = Paint()..color = AppColors.pinkDeep.withValues(alpha: 0.55);

    for (final double cx in const <double>[100, 132]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, 104), width: 22, height: 26), white);
    }
    canvas.drawCircle(const Offset(102, 107), 5.5, pupil);
    canvas.drawCircle(const Offset(134, 107), 5.5, pupil);
    canvas.drawCircle(const Offset(99.5, 103), 1.8, highlight);
    canvas.drawCircle(const Offset(131.5, 103), 1.8, highlight);

    canvas.drawOval(Rect.fromCenter(center: const Offset(86, 120), width: 18, height: 10), blush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(146, 120), width: 18, height: 10), blush);

    final Path smile = Path()
      ..moveTo(96, 128)
      ..quadraticBezierTo(116, 140, 136, 128);
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── arms (pose-specific) ──────────────────────────────────────────────

  void _paintArms(Canvas canvas) {
    final Paint limb = Paint()
      ..color = AppColors.pink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void arm(Offset from, Offset to, double width) {
      canvas.drawLine(from, to, limb..strokeWidth = width);
      canvas.drawCircle(to, width * 2 / 3, Paint()..color = AppColors.pink);
    }

    switch (pose) {
      case WelcomePose.coloring:
        arm(const Offset(70, 100), const Offset(54, 128), 15);
        arm(const Offset(150, 100), const Offset(180, 64), 15);
        break;
      case WelcomePose.games:
        arm(const Offset(70, 95), const Offset(48, 58), 15);
        arm(const Offset(150, 95), const Offset(172, 58), 15);
        arm(const Offset(100, 152), const Offset(88, 176), 13);
        arm(const Offset(132, 152), const Offset(144, 178), 13);
        break;
      case WelcomePose.rewards:
        arm(const Offset(70, 98), const Offset(50, 72), 15);
        arm(const Offset(150, 98), const Offset(176, 72), 15);
        break;
    }
  }

  // ── coloring props ────────────────────────────────────────────────────

  void _paintRainbow(Canvas canvas) {
    final List<(double, double, Color)> arcs = <(double, double, Color)>[
      (36, 55, AppColors.coral),
      (50, 66, AppColors.yellow),
      (64, 77, AppColors.teal),
    ];
    for (final (double startX, double apexY, Color color) in arcs) {
      final double endX = 236 - startX;
      final Path path = Path()
        ..moveTo(startX, 150)
        ..quadraticBezierTo(118, apexY, endX, 150);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintCrayon(Canvas canvas) {
    canvas.save();
    canvas.translate(180, 40);
    canvas.rotate(35 * math.pi / 180);
    final Paint wood = Paint()..color = AppColors.cream;
    final Paint body = Paint()..color = AppColors.yellow;
    final Paint tipBand = Paint()..color = AppColors.coral;
    canvas.drawPath(
      Path()
        ..moveTo(-8, -34)
        ..lineTo(8, -34)
        ..lineTo(0, -48)
        ..close(),
      wood,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -34, 16, 46), const Radius.circular(6)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -34, 16, 14), const Radius.circular(6)),
      tipBand,
    );
    canvas.restore();
  }

  void _paintFlecks(Canvas canvas) {
    canvas.drawCircle(const Offset(196, 46), 4, Paint()..color = AppColors.teal.withValues(alpha: 0.85));
    canvas.drawCircle(const Offset(26, 70), 3.4, Paint()..color = AppColors.yellow.withValues(alpha: 0.85));
    canvas.drawCircle(const Offset(24, 150), 3, Paint()..color = AppColors.coral.withValues(alpha: 0.7));
  }

  // ── games props ───────────────────────────────────────────────────────

  void _paintFloatingProps(Canvas canvas) {
    _paintStar(canvas, const Offset(190, 40), 1.15, 8, AppColors.yellow);
    _paintStar(canvas, const Offset(24, 132), 0.85, -10, AppColors.coral);
    _paintRoundedSquare(canvas, const Offset(28, 58), 16, 18, AppColors.teal);
    _paintRoundedSquare(canvas, const Offset(190, 146), -14, 18, AppColors.purple);
  }

  void _paintMotionDashes(Canvas canvas) {
    final Paint paint = Paint()..color = AppColors.dark.withValues(alpha: 0.12);
    for (final double dx in const <double>[-26, -4, 18]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(116 + dx, 184), width: 14, height: 4),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  // ── rewards props ─────────────────────────────────────────────────────

  void _paintFlame(Canvas canvas, Offset center, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawPath(_flamePath(16), Paint()..color = AppColors.orange);
    canvas.drawPath(_flamePath(8), Paint()..color = AppColors.yellow);
    canvas.restore();
  }

  Path _flamePath(double h) {
    final double k = h / 16;
    return Path()
      ..moveTo(0, -h)
      ..cubicTo(7 * k, -7 * k, 9 * k, 2 * k, 4 * k, 9 * k)
      ..cubicTo(7 * k, 4 * k, 2 * k, 0, 0, 5 * k)
      ..cubicTo(-2 * k, 0, -7 * k, 4 * k, -4 * k, 9 * k)
      ..cubicTo(-9 * k, 2 * k, -7 * k, -7 * k, 0, -h)
      ..close();
  }

  void _paintBadge(Canvas canvas) {
    const Offset hand = Offset(176, 72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: hand, width: 28, height: 28),
        const Radius.circular(9),
      ),
      Paint()..color = AppColors.teal,
    );
    _paintStar(canvas, hand, 0.85, 0, AppColors.yellow);
  }

  // ── shared prop helpers ──────────────────────────────────────────────

  void _paintStar(Canvas canvas, Offset center, double scale, double rotationDeg, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.rotate(rotationDeg * math.pi / 180);
    canvas.drawPath(_polygonPath(_starPoints), Paint()..color = color);
    canvas.restore();
  }

  void _paintSparkle(Canvas canvas, Offset center, double scale, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawPath(_polygonPath(_sparklePoints), Paint()..color = color);
    canvas.restore();
  }

  void _paintRoundedSquare(Canvas canvas, Offset center, double rotationDeg, double side, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDeg * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(side * 0.28),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }

  static Path _polygonPath(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static final List<Offset> _starPoints = <Offset>[
    const Offset(0, -10),
    const Offset(2.35, -3.24),
    const Offset(9.51, -3.09),
    const Offset(3.80, 1.24),
    const Offset(5.88, 8.09),
    const Offset(0, 4),
    const Offset(-5.88, 8.09),
    const Offset(-3.80, 1.24),
    const Offset(-9.51, -3.09),
    const Offset(-2.35, -3.24),
  ];

  static final List<Offset> _sparklePoints = <Offset>[
    const Offset(0, -8),
    const Offset(1.9, -2.6),
    const Offset(7.6, -2.5),
    const Offset(3, 1),
    const Offset(4.7, 6.5),
    const Offset(0, 3.2),
    const Offset(-4.7, 6.5),
    const Offset(-3, 1),
    const Offset(-7.6, -2.5),
    const Offset(-1.9, -2.6),
  ];

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) => oldDelegate.pose != pose;
}

class _Circle {
  const _Circle(this.cx, this.cy, this.r);
  final double cx;
  final double cy;
  final double r;
}
