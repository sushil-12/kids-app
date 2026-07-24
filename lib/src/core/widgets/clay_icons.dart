import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'clay_decor.dart';

/// Illustrated "clay" icon set — hand-drawn multi-color vector glyphs that
/// replace flat Material icons / raw emoji on the hub screens. Everything is
/// painted (no image assets), all hues derive from [AppColors], and each icon
/// sits in a glossy white clay badge so it reads as part of the pastel-clay
/// design language.
enum ClayIconKind {
  /// Paint brush with a paint drop (Coloring Studio).
  brush,

  /// Puzzle piece with a mini companion piece (Brain Games).
  puzzle,

  /// Open storybook with reading lines (Learn hub tile).
  book,

  /// Painter's palette with paint dabs (Creative / Color Match).
  palette,

  /// Tilted pencil drawing a squiggle (free draw).
  pencil,

  /// Closed book with sparkles popping out (Daily Story).
  storybook,

  /// Toy letter blocks A + B (ABC tutorial).
  abc,

  /// Beamed pair of music notes (Poems & Songs).
  music,

  /// Triangle, square and circle cluster (Shape Sorter).
  shapes,

  /// Face-down + face-up memory cards (Memory Flip).
  cards,

  /// Magnifying glass over an odd dot (Odd-One-Out).
  magnifier,

  /// Dotted letter A to trace (Letter Trace).
  trace,

  /// Trio of shiny apples (Count & Tap).
  apples,

  /// Shape sequence with a "what's next?" star (Pattern).
  pattern,

  /// Chunky golden star (stickers / rewards).
  star,

  /// Layered flame (daily streak).
  flame,
}

/// A [ClayIconKind] glyph inside a white clay circle with a soft tinted
/// drop shadow. Drop-in replacement for the old `CircleAvatar` + icon/emoji.
class ClayIcon extends StatelessWidget {
  const ClayIcon({
    required this.kind,
    required this.tint,
    this.size = 56,
    super.key,
  });

  final ClayIconKind kind;

  /// Accent color — used for the glyph body, badge rim and shadow.
  final Color tint;

  /// Badge diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tint.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ClayIconPainter(kind: kind, tint: tint),
        ),
      ),
    );
  }
}

/// Paints one glyph in a 100×100 logical box scaled to the badge size.
class _ClayIconPainter extends CustomPainter {
  const _ClayIconPainter({required this.kind, required this.tint});

  final ClayIconKind kind;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // Soft pastel rim keeps the badge from reading as a flat white disc.
    canvas.drawCircle(
      const Offset(50, 50),
      46.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = pastelOf(tint, 0.45),
    );

    switch (kind) {
      case ClayIconKind.brush:
        _brush(canvas);
      case ClayIconKind.puzzle:
        _puzzle(canvas);
      case ClayIconKind.book:
        _book(canvas);
      case ClayIconKind.palette:
        _palette(canvas);
      case ClayIconKind.pencil:
        _pencil(canvas);
      case ClayIconKind.storybook:
        _storybook(canvas);
      case ClayIconKind.abc:
        _abc(canvas);
      case ClayIconKind.music:
        _music(canvas);
      case ClayIconKind.shapes:
        _shapes(canvas);
      case ClayIconKind.cards:
        _cards(canvas);
      case ClayIconKind.magnifier:
        _magnifier(canvas);
      case ClayIconKind.trace:
        _trace(canvas);
      case ClayIconKind.apples:
        _apples(canvas);
      case ClayIconKind.pattern:
        _pattern(canvas);
      case ClayIconKind.star:
        _bigStar(canvas);
      case ClayIconKind.flame:
        _flame(canvas);
    }

    // Glossy sheen over the top-left, like light on soft clay.
    canvas.save();
    canvas.translate(33, 26);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 24, height: 9),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    canvas.restore();

    canvas.restore();
  }

  // ---- shared helpers -------------------------------------------------

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  /// Darker clay edge of [color] (same recipe as the ClayButton edge).
  Color _shade(Color color, [double t = 0.3]) =>
      Color.alphaBlend(AppColors.ink.withValues(alpha: t), color);

  Path _starPath(Offset c, double r) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double radius = i.isEven ? r : r * 0.45;
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final Offset p =
          c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final double waist = r * 0.24;
    final Path path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + waist, c.dy - waist, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + waist, c.dy + waist, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - waist, c.dy + waist, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - waist, c.dy - waist, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, _fill(color));
  }

  void _dotLine(Canvas canvas, Offset from, Offset to, int count, Paint paint) {
    for (int i = 0; i < count; i++) {
      final double t = count == 1 ? 0 : i / (count - 1);
      canvas.drawCircle(Offset.lerp(from, to, t)!, 2.6, paint);
    }
  }

  // ---- glyphs ---------------------------------------------------------

  void _brush(Canvas canvas) {
    // Paint drop + swoosh first, so the brush overlaps them.
    canvas.drawCircle(const Offset(67, 62), 5, _fill(pastelOf(tint, 0.85)));
    canvas.drawPath(
      Path()
        ..moveTo(30, 74)
        ..quadraticBezierTo(45, 82, 60, 74),
      _stroke(pastelOf(tint, 0.7), 4),
    );
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate(-0.6);
    // Wooden handle → metal ferrule → tinted bristles.
    final Color wood = Color.alphaBlend(
      AppColors.ink.withValues(alpha: 0.25),
      AppColors.orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-5, 2, 5, 32),
        const Radius.circular(5),
      ),
      _fill(wood),
    );
    canvas.drawRect(const Rect.fromLTRB(-6, -6, 6, 2), _fill(AppColors.grey));
    final Path bristles = Path()
      ..moveTo(-7, -6)
      ..quadraticBezierTo(-6, -18, 0, -26)
      ..quadraticBezierTo(6, -18, 7, -6)
      ..close();
    canvas.drawPath(bristles, _fill(tint));
    canvas.drawCircle(const Offset(0, -22), 2.5, _fill(_shade(tint)));
    canvas.restore();
  }

  void _puzzle(Canvas canvas) {
    final Path piece = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(32, 38, 64, 70),
          const Radius.circular(7),
        ),
      )
      ..addOval(Rect.fromCircle(center: const Offset(48, 38), radius: 7))
      ..addOval(Rect.fromCircle(center: const Offset(64, 54), radius: 7));
    // Hard bottom edge, then body, then highlight — the clay recipe.
    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(piece, _fill(_shade(tint)));
    canvas.restore();
    canvas.drawPath(piece, _fill(tint));
    canvas.drawCircle(
      const Offset(41, 47),
      4.5,
      _fill(Colors.white.withValues(alpha: 0.45)),
    );
    // Tiny second piece floating at the top right.
    canvas.save();
    canvas.translate(72, 30);
    canvas.rotate(0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-6, -6, 6, 6),
        const Radius.circular(3),
      ),
      _fill(AppColors.yellow),
    );
    canvas.restore();
  }

  void _book(Canvas canvas) {
    final Color cover = _shade(tint, 0.2);
    // Back cover peeks out under the pages.
    final Path coverPath = Path()
      ..moveTo(50, 36)
      ..quadraticBezierTo(36, 27, 23, 33)
      ..lineTo(23, 68)
      ..quadraticBezierTo(36, 62, 50, 71)
      ..quadraticBezierTo(64, 62, 77, 68)
      ..lineTo(77, 33)
      ..quadraticBezierTo(64, 27, 50, 36)
      ..close();
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(coverPath, _fill(cover));
    canvas.restore();
    final Path leftPage = Path()
      ..moveTo(50, 37)
      ..quadraticBezierTo(37, 29, 26, 34)
      ..lineTo(26, 65)
      ..quadraticBezierTo(37, 60, 50, 68)
      ..close();
    final Path rightPage = Path()
      ..moveTo(50, 37)
      ..quadraticBezierTo(63, 29, 74, 34)
      ..lineTo(74, 65)
      ..quadraticBezierTo(63, 60, 50, 68)
      ..close();
    canvas.drawPath(leftPage, _fill(Colors.white));
    canvas.drawPath(rightPage, _fill(pastelOf(tint, 0.14)));
    // Reading lines + spine.
    final Paint lines = _stroke(AppColors.slate.withValues(alpha: 0.45), 2.4);
    canvas.drawLine(const Offset(31, 42), const Offset(44, 44), lines);
    canvas.drawLine(const Offset(31, 49), const Offset(44, 51), lines);
    canvas.drawLine(const Offset(56, 44), const Offset(69, 42), lines);
    canvas.drawLine(const Offset(56, 51), const Offset(69, 49), lines);
    canvas.drawLine(const Offset(50, 37), const Offset(50, 68), _stroke(cover, 2.4));
    _sparkle(canvas, const Offset(72, 25), 5, AppColors.yellow);
  }

  void _palette(Canvas canvas) {
    final Color board = pastelOf(AppColors.orange, 0.5);
    final Rect blob = Rect.fromCenter(
      center: const Offset(50, 54),
      width: 56,
      height: 44,
    );
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawOval(blob, _fill(_shade(board, 0.18)));
    canvas.restore();
    canvas.drawOval(blob, _fill(board));
    canvas.drawCircle(const Offset(60, 62), 6, _fill(Colors.white));
    // Paint dabs along the top arc.
    canvas.drawCircle(const Offset(35, 49), 5, _fill(AppColors.coral));
    canvas.drawCircle(const Offset(45, 41), 5, _fill(AppColors.yellow));
    canvas.drawCircle(const Offset(58, 41), 5, _fill(AppColors.teal));
    canvas.drawCircle(const Offset(68, 49), 4.5, _fill(AppColors.purple));
  }

  void _pencil(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(28, 76)
        ..quadraticBezierTo(38, 66, 48, 74)
        ..quadraticBezierTo(58, 81, 70, 72),
      _stroke(pastelOf(tint, 0.75), 3.6),
    );
    canvas.save();
    canvas.translate(52, 44);
    canvas.rotate(0.62);
    // Eraser cap → band → body → wood tip → lead.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-6.5, -32, 6.5, -25),
        const Radius.circular(3),
      ),
      _fill(AppColors.pink),
    );
    canvas.drawRect(const Rect.fromLTRB(-6.5, -25, 6.5, -21), _fill(AppColors.grey));
    canvas.drawRect(const Rect.fromLTRB(-6.5, -21, 6.5, 12), _fill(tint));
    canvas.drawLine(
      const Offset(0, -20),
      const Offset(0, 11),
      _stroke(Colors.white.withValues(alpha: 0.35), 3),
    );
    final Path wood = Path()
      ..moveTo(-6.5, 12)
      ..lineTo(6.5, 12)
      ..lineTo(0, 26)
      ..close();
    canvas.drawPath(wood, _fill(pastelOf(AppColors.orange, 0.6)));
    final Path lead = Path()
      ..moveTo(-2.2, 21)
      ..lineTo(2.2, 21)
      ..lineTo(0, 26)
      ..close();
    canvas.drawPath(lead, _fill(AppColors.ink));
    canvas.restore();
  }

  void _storybook(Canvas canvas) {
    canvas.save();
    canvas.translate(50, 58);
    canvas.rotate(-0.08);
    // Page block behind the cover, then cover + spine.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-15, -14, 20, 15),
        const Radius.circular(3),
      ),
      _fill(pastelOf(AppColors.orange, 0.35)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-19, -16, 17, 13),
        const Radius.circular(4),
      ),
      _fill(tint),
    );
    canvas.drawRect(const Rect.fromLTRB(-19, -16, -12, 13), _fill(_shade(tint)));
    canvas.drawPath(
      _starPath(const Offset(3, -1.5), 8),
      _fill(Colors.white.withValues(alpha: 0.9)),
    );
    canvas.restore();
    _sparkle(canvas, const Offset(66, 28), 6, AppColors.yellow);
    _sparkle(canvas, const Offset(33, 26), 4, pastelOf(tint, 0.85));
    canvas.drawCircle(const Offset(74, 42), 2.2, _fill(AppColors.coral));
  }

  void _abc(Canvas canvas) {
    // Back block "B".
    canvas.save();
    canvas.translate(61, 44);
    canvas.rotate(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-13, -13, 13, 13),
        const Radius.circular(5),
      ),
      _fill(pastelOf(AppColors.teal, 0.45)),
    );
    final Path letterB = Path()
      ..moveTo(-4, -6)
      ..lineTo(-4, 6)
      ..moveTo(-4, -6)
      ..quadraticBezierTo(5, -6, 5, -3)
      ..quadraticBezierTo(5, 0, -4, 0)
      ..moveTo(-4, 0)
      ..quadraticBezierTo(6, 0, 6, 3)
      ..quadraticBezierTo(6, 6, -4, 6);
    canvas.drawPath(letterB, _stroke(_shade(AppColors.teal, 0.15), 3));
    canvas.restore();
    // Front block "A".
    canvas.save();
    canvas.translate(39, 58);
    canvas.rotate(-0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-14, -14, 14, 14),
        const Radius.circular(5),
      ),
      _fill(pastelOf(AppColors.coral, 0.45)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-14, -14, 14, 14),
        const Radius.circular(5),
      ),
      _stroke(Colors.white, 2.2),
    );
    final Path letterA = Path()
      ..moveTo(0, -8)
      ..lineTo(-7, 8)
      ..moveTo(0, -8)
      ..lineTo(7, 8)
      ..moveTo(-4, 2)
      ..lineTo(4, 2);
    canvas.drawPath(letterA, _stroke(_shade(AppColors.coral, 0.15), 3.4));
    canvas.restore();
    _sparkle(canvas, const Offset(70, 68), 4.5, AppColors.yellow);
  }

  void _music(Canvas canvas) {
    final Color dark = _shade(tint, 0.2);
    // Beam connecting the two stems.
    final Path beam = Path()
      ..moveTo(39, 30)
      ..lineTo(67, 24)
      ..lineTo(67, 32)
      ..lineTo(39, 38)
      ..close();
    canvas.drawPath(beam, _fill(dark));
    canvas.drawLine(const Offset(41, 34), const Offset(41, 60), _stroke(dark, 4));
    canvas.drawLine(const Offset(65, 28), const Offset(65, 54), _stroke(dark, 4));
    // Note heads, slightly tilted.
    canvas.save();
    canvas.translate(36, 62);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 15, height: 11),
      _fill(tint),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(60, 56);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 15, height: 11),
      _fill(AppColors.coral),
    );
    canvas.restore();
    _sparkle(canvas, const Offset(74, 66), 5, AppColors.yellow);
  }

  void _shapes(Canvas canvas) {
    final Paint rim = _stroke(Colors.white, 2.5);
    final Path triangle = Path()
      ..moveTo(38, 28)
      ..lineTo(25, 51)
      ..lineTo(51, 51)
      ..close();
    canvas.drawPath(triangle, _fill(AppColors.coral));
    canvas.drawPath(triangle, rim);
    final RRect square = RRect.fromRectAndRadius(
      const Rect.fromLTRB(56, 32, 76, 52),
      const Radius.circular(4),
    );
    canvas.drawRRect(square, _fill(AppColors.teal));
    canvas.drawRRect(square, rim);
    canvas.drawCircle(const Offset(50, 66), 11, _fill(AppColors.yellow));
    canvas.drawCircle(const Offset(50, 66), 11, rim);
    // Little light catches.
    final Paint gleam = _fill(Colors.white.withValues(alpha: 0.5));
    canvas.drawCircle(const Offset(38, 44), 2.4, gleam);
    canvas.drawCircle(const Offset(62, 38), 2.4, gleam);
    canvas.drawCircle(const Offset(46, 62), 2.4, gleam);
  }

  void _cards(Canvas canvas) {
    // Face-down card with a dot pattern.
    canvas.save();
    canvas.translate(41, 48);
    canvas.rotate(-0.16);
    final RRect back = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-12, -16, 12, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(back, _fill(pastelOf(tint, 0.55)));
    canvas.drawRRect(back, _stroke(Colors.white, 2.2));
    final Paint dot = _fill(_shade(tint, 0.1));
    canvas.drawCircle(const Offset(-5, -7), 2.2, dot);
    canvas.drawCircle(const Offset(5, -7), 2.2, dot);
    canvas.drawCircle(const Offset(-5, 3), 2.2, dot);
    canvas.drawCircle(const Offset(5, 3), 2.2, dot);
    canvas.drawCircle(const Offset(0, 10), 2.2, dot);
    canvas.restore();
    // Face-up card revealing a star.
    canvas.save();
    canvas.translate(59, 54);
    canvas.rotate(0.14);
    final RRect front = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-12, -16, 12, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(front, _fill(Colors.white));
    canvas.drawRRect(front, _stroke(tint, 2.4));
    canvas.drawPath(_starPath(Offset.zero, 8), _fill(AppColors.yellow));
    canvas.restore();
  }

  void _magnifier(Canvas canvas) {
    canvas.drawCircle(const Offset(44, 44), 15, _fill(pastelOf(AppColors.blue, 0.3)));
    // One of these dots is not like the others…
    canvas.drawCircle(const Offset(38, 41), 3.2, _fill(AppColors.teal));
    canvas.drawCircle(const Offset(49, 39), 3.2, _fill(AppColors.teal));
    canvas.drawCircle(const Offset(44, 50), 3.6, _fill(AppColors.coral));
    canvas.drawCircle(const Offset(44, 44), 15, _stroke(tint, 5));
    canvas.drawLine(
      const Offset(56, 56),
      const Offset(69, 69),
      _stroke(_shade(tint), 7),
    );
    _sparkle(canvas, const Offset(68, 30), 4.5, AppColors.yellow);
  }

  void _trace(Canvas canvas) {
    final Paint dots = _fill(tint);
    _dotLine(canvas, const Offset(50, 28), const Offset(35, 70), 6, dots);
    _dotLine(canvas, const Offset(50, 28), const Offset(65, 70), 6, dots);
    _dotLine(canvas, const Offset(42.5, 55), const Offset(57.5, 55), 3, dots);
    // Green "start here" dot at the apex, star for the finish.
    canvas.drawCircle(const Offset(50, 28), 4, _fill(AppColors.green));
    _sparkle(canvas, const Offset(70, 32), 5, AppColors.yellow);
  }

  void _apples(Canvas canvas) {
    void apple(Offset c, double r, Color color) {
      canvas.drawLine(
        c.translate(0, -r),
        c.translate(0, -r - 4),
        _stroke(_shade(AppColors.green, 0.4), 2.4),
      );
      canvas.save();
      canvas.translate(c.dx + 3, c.dy - r - 3);
      canvas.rotate(-0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 9, height: 5),
        _fill(AppColors.green),
      );
      canvas.restore();
      canvas.drawCircle(c, r, _fill(color));
      canvas.drawCircle(
        c.translate(-r * 0.35, -r * 0.35),
        r * 0.28,
        _fill(Colors.white.withValues(alpha: 0.55)),
      );
    }

    apple(const Offset(36, 50), 10.5, AppColors.crimson);
    apple(const Offset(64, 50), 10.5, AppColors.green);
    apple(const Offset(50, 68), 9.5, AppColors.yellow);
  }

  void _pattern(Canvas canvas) {
    // The sequence so far: circle, square, circle…
    canvas.drawCircle(const Offset(32, 42), 7, _fill(AppColors.teal));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(44, 35, 58, 49),
        const Radius.circular(3),
      ),
      _fill(AppColors.coral),
    );
    canvas.drawCircle(const Offset(69, 42), 7, _fill(AppColors.teal));
    // …and the "what's next?" slot below.
    final RRect slot = RRect.fromRectAndRadius(
      const Rect.fromLTRB(41, 56, 61, 76),
      const Radius.circular(5),
    );
    canvas.drawRRect(slot, _stroke(AppColors.slate.withValues(alpha: 0.4), 2));
    canvas.drawPath(_starPath(const Offset(51, 66), 7), _fill(AppColors.yellow));
  }

  void _bigStar(Canvas canvas) {
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      _starPath(const Offset(50, 51), 25),
      _fill(_shade(AppColors.yellow, 0.2)),
    );
    canvas.restore();
    canvas.drawPath(_starPath(const Offset(50, 51), 25), _fill(AppColors.yellow));
    canvas.drawCircle(
      const Offset(44, 46),
      4,
      _fill(Colors.white.withValues(alpha: 0.6)),
    );
    _sparkle(canvas, const Offset(74, 32), 5, AppColors.orange);
    _sparkle(canvas, const Offset(26, 66), 4, AppColors.coral);
  }

  void _flame(Canvas canvas) {
    final Path outer = Path()
      ..moveTo(50, 22)
      ..quadraticBezierTo(66, 40, 69, 56)
      ..quadraticBezierTo(70, 74, 50, 78)
      ..quadraticBezierTo(30, 74, 31, 56)
      ..quadraticBezierTo(32, 46, 40, 36)
      ..quadraticBezierTo(39, 46, 46, 48)
      ..quadraticBezierTo(43, 34, 50, 22)
      ..close();
    canvas.drawPath(outer, _fill(AppColors.orange));
    final Path inner = Path()
      ..moveTo(50, 44)
      ..quadraticBezierTo(59, 53, 59, 62)
      ..quadraticBezierTo(59, 72, 50, 74)
      ..quadraticBezierTo(41, 72, 41, 62)
      ..quadraticBezierTo(41, 53, 50, 44)
      ..close();
    canvas.drawPath(inner, _fill(AppColors.yellow));
    canvas.drawCircle(const Offset(50, 67), 5, _fill(pastelOf(AppColors.yellow, 0.35)));
  }

  @override
  bool shouldRepaint(_ClayIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.tint != tint;
}
