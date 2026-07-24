import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/cinematic_story.dart';
import 'scene_painter.dart';

// ---------------------------------------------------------------------------
// SceneParticlesPainter — ambient motion for the cinematic stage.
//
// Driven by a looping [Animation<double>] (0..1) passed as `repaint`, so
// Flutter repaints only this layer per frame; the static stage below sits in
// its own RepaintBoundary. Particle layouts are deterministic (fixed seeds),
// so a scene always shakes out identically and shouldRepaint stays a cheap
// identity check.
// ---------------------------------------------------------------------------

class SceneParticlesPainter extends CustomPainter {
  SceneParticlesPainter({required this.particles, required this.time})
      : super(repaint: time);

  final List<ParticleKind> particles;

  /// Looping 0..1 progress; one full lap ≈ 8s (see the player screen).
  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = time.value;
    for (final ParticleKind kind in particles) {
      switch (kind) {
        case ParticleKind.sunRays:
          _paintSunRays(canvas, size, t);
        case ParticleKind.wind:
          _paintWind(canvas, size, t);
        case ParticleKind.birds:
          _paintBirds(canvas, size, t);
        case ParticleKind.leaves:
          _paintLeaves(canvas, size, t);
        case ParticleKind.rain:
          _paintRain(canvas, size, t);
        case ParticleKind.stars:
          _paintStars(canvas, size, t);
        case ParticleKind.bubbles:
          _paintBubbles(canvas, size, t);
      }
    }
  }

  @override
  bool shouldRepaint(SceneParticlesPainter oldDelegate) =>
      oldDelegate.particles != particles || oldDelegate.time != time;

  void _paintSunRays(Canvas canvas, Size size, double t) {
    // Slow-breathing translucent beams from the top of the stage.
    final double pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final Paint paint = Paint()
      ..color = ScenePalette.sunYellow.withValues(alpha: 0.10 + 0.08 * pulse)
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final double x = size.width * (0.2 + i * 0.22);
      canvas.drawLine(
        Offset(x + size.width * 0.12, 0),
        Offset(x - size.width * 0.08, size.height * 0.55),
        paint,
      );
    }
  }

  void _paintWind(Canvas canvas, Size size, double t) {
    final Paint paint = Paint()
      ..color = ScenePalette.cloudWhite.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.008
      ..strokeCap = StrokeCap.round;
    final math.Random rng = math.Random(7);
    for (int i = 0; i < 3; i++) {
      final double y = size.height * (0.18 + rng.nextDouble() * 0.4);
      final double phase = rng.nextDouble();
      // Each swirl travels the full width once per lap, offset by its phase.
      final double x =
          ((t + phase) % 1.0) * (size.width * 1.4) - size.width * 0.2;
      final double w = size.width * 0.22;
      final Path path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + w * 0.35,
          y - size.height * 0.02,
          x + w * 0.7,
          y,
        )
        ..quadraticBezierTo(
          x + w * 0.9,
          y + size.height * 0.012,
          x + w,
          y - size.height * 0.008,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintBirds(Canvas canvas, Size size, double t) {
    final Paint paint = Paint()
      ..color = ScenePalette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.008
      ..strokeCap = StrokeCap.round;
    final math.Random rng = math.Random(11);
    for (int i = 0; i < 3; i++) {
      final double phase = rng.nextDouble();
      final double y = size.height * (0.1 + rng.nextDouble() * 0.22);
      final double x =
          ((t * 0.6 + phase) % 1.0) * (size.width * 1.3) - size.width * 0.15;
      final double flap =
          math.sin((t * 6 + i) * 2 * math.pi) * size.height * 0.008;
      final double s = size.shortestSide * 0.02;
      final Path bird = Path()
        ..moveTo(x - s, y + flap)
        ..quadraticBezierTo(x - s * 0.4, y - s * 0.8 - flap, x, y)
        ..quadraticBezierTo(x + s * 0.4, y - s * 0.8 - flap, x + s, y + flap);
      canvas.drawPath(bird, paint);
    }
  }

  void _paintLeaves(Canvas canvas, Size size, double t) {
    final Paint paint = Paint()
      ..color = ScenePalette.leafGreen.withValues(alpha: 0.8);
    final math.Random rng = math.Random(13);
    for (int i = 0; i < 6; i++) {
      final double phase = rng.nextDouble();
      final double x0 = rng.nextDouble() * size.width;
      final double fall = (t + phase) % 1.0;
      final double x =
          x0 + math.sin(fall * 4 * math.pi + i) * size.width * 0.05;
      final double y = fall * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fall * 4 * math.pi + i);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.shortestSide * 0.022,
          height: size.shortestSide * 0.012,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintRain(Canvas canvas, Size size, double t) {
    final Paint paint = Paint()
      ..color = ScenePalette.water.withValues(alpha: 0.6)
      ..strokeWidth = size.shortestSide * 0.006
      ..strokeCap = StrokeCap.round;
    final math.Random rng = math.Random(17);
    for (int i = 0; i < 18; i++) {
      final double phase = rng.nextDouble();
      final double x = rng.nextDouble() * size.width;
      final double fall = (t * 3 + phase) % 1.0;
      final double y = fall * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - size.width * 0.008, y + size.height * 0.03),
        paint,
      );
    }
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final math.Random rng = math.Random(19);
    for (int i = 0; i < 14; i++) {
      final double x = rng.nextDouble() * size.width;
      final double y = rng.nextDouble() * size.height * 0.5;
      final double phase = rng.nextDouble();
      final double twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((t + phase) * 4 * math.pi));
      canvas.drawCircle(
        Offset(x, y),
        size.shortestSide * (0.004 + 0.004 * twinkle),
        Paint()..color = ScenePalette.starGold.withValues(alpha: twinkle),
      );
    }
  }

  void _paintBubbles(Canvas canvas, Size size, double t) {
    final Paint paint = Paint()
      ..color = ScenePalette.water.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.006;
    final math.Random rng = math.Random(23);
    for (int i = 0; i < 7; i++) {
      final double phase = rng.nextDouble();
      final double x0 = size.width * (0.3 + rng.nextDouble() * 0.4);
      final double rise = (t + phase) % 1.0;
      final double x =
          x0 + math.sin(rise * 3 * math.pi + i) * size.width * 0.03;
      final double y = size.height * (0.85 - rise * 0.5);
      canvas.drawCircle(
        Offset(x, y),
        size.shortestSide * (0.008 + rng.nextDouble() * 0.01),
        paint,
      );
    }
  }
}
