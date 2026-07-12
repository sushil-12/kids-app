import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/cinematic_story.dart';

// ---------------------------------------------------------------------------
// ScenePainter — the render layer of the cinematic story player.
//
// Draws a scene's background preset and its props as pure vector shapes in a
// single pass, so stories need zero image assets. Characters are positioned
// emoji widgets layered on top (see story_player_screen.dart), and particles
// are a separate time-driven painter (scene_particles.dart) so the static
// stage never repaints per frame.
// ---------------------------------------------------------------------------

/// Scene palette — stage colors live here (like the coloring templates keep
/// theirs in data) so widgets stay on AppColors only.
abstract final class ScenePalette {
  static const Color hotSkyTop = Color(0xFFFFE29A);
  static const Color hotSkyBottom = Color(0xFFFFB65C);
  static const Color daySkyTop = Color(0xFF8ED4F5);
  static const Color daySkyBottom = Color(0xFFD9F1FC);
  static const Color nightSkyTop = Color(0xFF232052);
  static const Color nightSkyBottom = Color(0xFF4A4380);
  static const Color rainSkyTop = Color(0xFF7C8DA6);
  static const Color rainSkyBottom = Color(0xFFB4C2D4);
  static const Color forestSkyTop = Color(0xFFB9E8C9);
  static const Color forestSkyBottom = Color(0xFFE8F8EE);
  static const Color groundGreen = Color(0xFF8FCB6B);
  static const Color groundDry = Color(0xFFE8C97C);
  static const Color groundDark = Color(0xFF3E5E43);
  static const Color water = Color(0xFF64B7E6);
  static const Color waterDeep = Color(0xFF3F92C4);
  static const Color sunYellow = Color(0xFFFFCC40);
  static const Color sunOrange = Color(0xFFFFA53D);
  static const Color cloudWhite = Color(0xFFFFFFFF);
  static const Color trunkBrown = Color(0xFF8C6239);
  static const Color leafGreen = Color(0xFF5FA84E);
  static const Color leafDark = Color(0xFF447B38);
  static const Color potBrown = Color(0xFFB5713C);
  static const Color potDark = Color(0xFF8C532B);
  static const Color houseWall = Color(0xFFFFF1D6);
  static const Color houseRoof = Color(0xFFE2704A);
  static const Color rockGrey = Color(0xFF9B938F);
  static const Color mountainGrey = Color(0xFF8A93B8);
  static const Color snowWhite = Color(0xFFF4F8FF);
  static const Color flowerPink = Color(0xFFFF99BF);
  static const Color flowerCenter = Color(0xFFFFCC40);
  static const Color starGold = Color(0xFFFFE082);
  static const Color moonPale = Color(0xFFF6F1D9);
  static const Color outline = Color(0x33332E40);
}

/// Paints one scene's background + props. Repaints only when the scene
/// changes identity (scene transitions), never per animation frame.
class ScenePainter extends CustomPainter {
  ScenePainter({required this.scene});

  final StoryScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    for (final SceneProp prop in scene.props) {
      _paintProp(canvas, size, prop);
    }
  }

  @override
  bool shouldRepaint(ScenePainter oldDelegate) => oldDelegate.scene != scene;

  // ---- Background presets --------------------------------------------------

  void _paintBackground(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final (Color top, Color bottom, Color ground) = switch (scene.background) {
      SceneBackground.hotDay => (
          ScenePalette.hotSkyTop,
          ScenePalette.hotSkyBottom,
          ScenePalette.groundDry,
        ),
      SceneBackground.forest => (
          ScenePalette.forestSkyTop,
          ScenePalette.forestSkyBottom,
          ScenePalette.groundGreen,
        ),
      SceneBackground.night => (
          ScenePalette.nightSkyTop,
          ScenePalette.nightSkyBottom,
          ScenePalette.groundDark,
        ),
      SceneBackground.pond => (
          ScenePalette.daySkyTop,
          ScenePalette.daySkyBottom,
          ScenePalette.groundGreen,
        ),
      SceneBackground.village => (
          ScenePalette.daySkyTop,
          ScenePalette.daySkyBottom,
          ScenePalette.groundGreen,
        ),
      SceneBackground.sky => (
          ScenePalette.daySkyTop,
          ScenePalette.daySkyBottom,
          ScenePalette.daySkyBottom,
        ),
      SceneBackground.rain => (
          ScenePalette.rainSkyTop,
          ScenePalette.rainSkyBottom,
          ScenePalette.groundGreen,
        ),
    };

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, bottom],
        ).createShader(rect),
    );

    // Rolling ground with a soft horizon bump (skipped for pure-sky scenes).
    if (scene.background != SceneBackground.sky) {
      final double horizon = size.height * 0.72;
      final Path groundPath = Path()
        ..moveTo(0, horizon + size.height * 0.04)
        ..quadraticBezierTo(
          size.width * 0.3,
          horizon - size.height * 0.03,
          size.width * 0.62,
          horizon + size.height * 0.015,
        )
        ..quadraticBezierTo(
          size.width * 0.85,
          horizon + size.height * 0.045,
          size.width,
          horizon + size.height * 0.01,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(groundPath, Paint()..color = ground);
    }

    // Preset dressing that sells the mood without needing props.
    switch (scene.background) {
      case SceneBackground.pond:
        final Rect pondRect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.87),
          width: size.width * 0.75,
          height: size.height * 0.18,
        );
        canvas.drawOval(pondRect, Paint()..color = ScenePalette.water);
        canvas.drawOval(
          pondRect.deflate(size.shortestSide * 0.03),
          Paint()..color = ScenePalette.waterDeep.withValues(alpha: 0.35),
        );
      case SceneBackground.forest:
        // Distant canopy silhouettes along the horizon.
        final Paint far = Paint()
          ..color = ScenePalette.leafDark.withValues(alpha: 0.35);
        for (int i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(size.width * (0.1 + i * 0.2), size.height * 0.7),
            size.shortestSide * (0.09 + (i.isEven ? 0.02 : 0)),
            far,
          );
        }
      case SceneBackground.night:
        // A soft moon glow; explicit moon/star props add the rest.
        canvas.drawCircle(
          Offset(size.width * 0.8, size.height * 0.18),
          size.shortestSide * 0.12,
          Paint()..color = ScenePalette.moonPale.withValues(alpha: 0.18),
        );
      case SceneBackground.hotDay:
        // Heat shimmer band above the horizon.
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.05),
          Paint()..color = ScenePalette.hotSkyBottom.withValues(alpha: 0.4),
        );
      case SceneBackground.village:
      case SceneBackground.sky:
      case SceneBackground.rain:
        break;
    }
  }

  // ---- Props ----------------------------------------------------------------

  void _paintProp(Canvas canvas, Size size, SceneProp prop) {
    final Offset c = Offset(prop.x * size.width, prop.y * size.height);
    final double r = size.shortestSide * 0.09 * prop.scale;

    switch (prop.kind) {
      case PropKind.sun:
        _paintSun(canvas, c, r);
      case PropKind.cloud:
        _paintCloud(canvas, c, r);
      case PropKind.tree:
        _paintTree(canvas, c, r);
      case PropKind.pot:
        _paintPot(canvas, c, r);
      case PropKind.pond:
        canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 3.2, height: r * 1.3),
          Paint()..color = ScenePalette.water,
        );
      case PropKind.house:
        _paintHouse(canvas, c, r);
      case PropKind.rock:
        _paintRock(canvas, c, r);
      case PropKind.bush:
        _paintBush(canvas, c, r);
      case PropKind.mountain:
        _paintMountain(canvas, c, r);
      case PropKind.flower:
        _paintFlower(canvas, c, r);
      case PropKind.star:
        _paintStar(canvas, c, r * 0.8, ScenePalette.starGold);
      case PropKind.moon:
        _paintMoon(canvas, c, r);
    }
  }

  void _paintSun(Canvas canvas, Offset c, double r) {
    final Paint ray = Paint()
      ..color = ScenePalette.sunOrange.withValues(alpha: 0.8)
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 1.25),
        c + Offset(math.cos(a), math.sin(a)) * (r * 1.7),
        ray,
      );
    }
    canvas.drawCircle(c, r, Paint()..color = ScenePalette.sunYellow);
    canvas.drawCircle(
      c,
      r * 0.75,
      Paint()..color = ScenePalette.sunOrange.withValues(alpha: 0.35),
    );
  }

  void _paintCloud(Canvas canvas, Offset c, double r) {
    final Paint paint = Paint()
      ..color = ScenePalette.cloudWhite.withValues(alpha: 0.92);
    canvas.drawCircle(c + Offset(-r * 0.7, r * 0.1), r * 0.6, paint);
    canvas.drawCircle(c + Offset(-r * 0.05, -r * 0.25), r * 0.75, paint);
    canvas.drawCircle(c + Offset(r * 0.65, r * 0.1), r * 0.55, paint);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.25), width: r * 2.4, height: r),
      paint,
    );
  }

  void _paintTree(Canvas canvas, Offset c, double r) {
    final RRect trunk = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.9),
        width: r * 0.42,
        height: r * 1.6,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(trunk, Paint()..color = ScenePalette.trunkBrown);
    final Paint leaves = Paint()..color = ScenePalette.leafGreen;
    canvas.drawCircle(c + Offset(-r * 0.6, 0), r * 0.72, leaves);
    canvas.drawCircle(c + Offset(r * 0.6, 0), r * 0.72, leaves);
    canvas.drawCircle(c + Offset(0, -r * 0.55), r * 0.85, leaves);
    canvas.drawCircle(
      c + Offset(0, -r * 0.1),
      r * 0.9,
      Paint()..color = ScenePalette.leafDark.withValues(alpha: 0.25),
    );
  }

  void _paintPot(Canvas canvas, Offset c, double r) {
    final Path body = Path()
      ..moveTo(c.dx - r * 0.55, c.dy - r * 0.7)
      ..quadraticBezierTo(c.dx - r * 1.05, c.dy + r * 0.1, c.dx - r * 0.5, c.dy + r * 0.75)
      ..lineTo(c.dx + r * 0.5, c.dy + r * 0.75)
      ..quadraticBezierTo(c.dx + r * 1.05, c.dy + r * 0.1, c.dx + r * 0.55, c.dy - r * 0.7)
      ..close();
    canvas.drawPath(body, Paint()..color = ScenePalette.potBrown);
    // Rim.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, -r * 0.7),
        width: r * 1.3,
        height: r * 0.42,
      ),
      Paint()..color = ScenePalette.potDark,
    );
    // Water inside, visible from above.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, -r * 0.7),
        width: r * 0.95,
        height: r * 0.28,
      ),
      Paint()..color = ScenePalette.water,
    );
  }

  void _paintHouse(Canvas canvas, Offset c, double r) {
    canvas.drawRect(
      Rect.fromCenter(center: c + Offset(0, r * 0.3), width: r * 1.7, height: r * 1.3),
      Paint()..color = ScenePalette.houseWall,
    );
    final Path roof = Path()
      ..moveTo(c.dx - r * 1.05, c.dy - r * 0.35)
      ..lineTo(c.dx, c.dy - r * 1.15)
      ..lineTo(c.dx + r * 1.05, c.dy - r * 0.35)
      ..close();
    canvas.drawPath(roof, Paint()..color = ScenePalette.houseRoof);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, r * 0.62),
          width: r * 0.45,
          height: r * 0.66,
        ),
        Radius.circular(r * 0.18),
      ),
      Paint()..color = ScenePalette.trunkBrown,
    );
  }

  void _paintRock(Canvas canvas, Offset c, double r) {
    final Paint paint = Paint()..color = ScenePalette.rockGrey;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.5, height: r),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(r * 0.55, r * 0.12),
        width: r * 0.9,
        height: r * 0.7,
      ),
      paint,
    );
  }

  void _paintBush(Canvas canvas, Offset c, double r) {
    final Paint paint = Paint()..color = ScenePalette.leafGreen;
    canvas.drawCircle(c + Offset(-r * 0.55, r * 0.1), r * 0.5, paint);
    canvas.drawCircle(c + Offset(0, -r * 0.12), r * 0.6, paint);
    canvas.drawCircle(c + Offset(r * 0.55, r * 0.1), r * 0.5, paint);
  }

  void _paintMountain(Canvas canvas, Offset c, double r) {
    final Path peak = Path()
      ..moveTo(c.dx - r * 1.5, c.dy + r * 0.9)
      ..lineTo(c.dx, c.dy - r * 1.2)
      ..lineTo(c.dx + r * 1.5, c.dy + r * 0.9)
      ..close();
    canvas.drawPath(peak, Paint()..color = ScenePalette.mountainGrey);
    final Path snow = Path()
      ..moveTo(c.dx - r * 0.42, c.dy - r * 0.45)
      ..lineTo(c.dx, c.dy - r * 1.2)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.45)
      ..quadraticBezierTo(c.dx + r * 0.2, c.dy - r * 0.3, c.dx, c.dy - r * 0.45)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy - r * 0.3, c.dx - r * 0.42, c.dy - r * 0.45)
      ..close();
    canvas.drawPath(snow, Paint()..color = ScenePalette.snowWhite);
  }

  void _paintFlower(Canvas canvas, Offset c, double r) {
    canvas.drawLine(
      c + Offset(0, r * 0.2),
      c + Offset(0, r * 1.2),
      Paint()
        ..color = ScenePalette.leafDark
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round,
    );
    final Paint petal = Paint()..color = ScenePalette.flowerPink;
    for (int i = 0; i < 6; i++) {
      final double a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.42),
        r * 0.3,
        petal,
      );
    }
    canvas.drawCircle(c, r * 0.26, Paint()..color = ScenePalette.flowerCenter);
  }

  void _paintStar(Canvas canvas, Offset c, double r, Color color) {
    final Path path = Path();
    for (int i = 0; i < 5; i++) {
      final double outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final double inner = outer + math.pi / 5;
      final Offset po = c + Offset(math.cos(outer), math.sin(outer)) * r;
      final Offset pi = c + Offset(math.cos(inner), math.sin(inner)) * (r * 0.45);
      if (i == 0) {
        path.moveTo(po.dx, po.dy);
      } else {
        path.lineTo(po.dx, po.dy);
      }
      path.lineTo(pi.dx, pi.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintMoon(Canvas canvas, Offset c, double r) {
    final Path crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()
        ..addOval(Rect.fromCircle(center: c + Offset(r * 0.45, -r * 0.2), radius: r * 0.85)),
    );
    canvas.drawPath(crescent, Paint()..color = ScenePalette.moonPale);
  }
}
