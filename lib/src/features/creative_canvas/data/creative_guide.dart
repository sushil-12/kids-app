import 'package:flutter/widgets.dart';

import '../../games/shared/shape_view.dart';

/// What kind of drawing the child is doing on the Creative Canvas.
///
/// * [freeDraw]   – a blank page, no guide.
/// * [traceShape] – a faint geometric shape to trace over.
/// * [traceFruit] – a faint fruit outline to trace over.
enum CreativeMode { freeDraw, traceShape, traceFruit }

/// A trace template for the Creative Canvas: a faint outline (one or more
/// [guidePaths]) the child draws over to practise control. Authored in a
/// 100×100 [viewBox] so it scales crisply to any canvas size — the same
/// coordinate convention as the Coloring Studio.
@immutable
class TraceGuide {
  const TraceGuide({
    required this.id,
    required this.titleKey,
    required this.emoji,
    required this.mode,
    required this.guidePaths,
    required this.stickerRewardId,
    this.viewBox = 100,
  });

  final String id;

  /// Localization key for the guide's name (resolved in the view).
  final String titleKey;
  final String emoji;
  final CreativeMode mode;
  final double viewBox;
  final List<Path> guidePaths;

  /// Sticker awarded on finishing. Unknown ids fall back to a random sticker
  /// (see [RewardsViewModel.awardById]), so a win is never dropped.
  final String stickerRewardId;
}

/// Sentinel guide id for the blank free-draw page (no guide).
const String kFreeDrawId = 'free';

/// All bundled trace guides — shapes then fruits. Original vector geometry,
/// no third-party assets.
final List<TraceGuide> kCreativeGuides = <TraceGuide>[
  // ----- shapes (reuse the Shape Sorter geometry) -----
  _shapeGuide('shape_circle', '⭕', ShapeKind.circle, 'palette'),
  _shapeGuide('shape_square', '🟧', ShapeKind.square, 'palette'),
  _shapeGuide('shape_triangle', '🔺', ShapeKind.triangle, 'palette'),
  _shapeGuide('shape_star', '⭐', ShapeKind.star, 'star'),
  _shapeGuide('shape_heart', '❤️', ShapeKind.heart, 'balloon'),
  // ----- fruits -----
  TraceGuide(
    id: 'fruit_apple',
    titleKey: 'fruitApple',
    emoji: '🍎',
    mode: CreativeMode.traceFruit,
    stickerRewardId: 'apple',
    guidePaths: _apple(),
  ),
  TraceGuide(
    id: 'fruit_banana',
    titleKey: 'fruitBanana',
    emoji: '🍌',
    mode: CreativeMode.traceFruit,
    stickerRewardId: 'palette',
    guidePaths: _banana(),
  ),
  TraceGuide(
    id: 'fruit_pear',
    titleKey: 'fruitPear',
    emoji: '🍐',
    mode: CreativeMode.traceFruit,
    stickerRewardId: 'palette',
    guidePaths: _pear(),
  ),
  TraceGuide(
    id: 'fruit_grapes',
    titleKey: 'fruitGrapes',
    emoji: '🍇',
    mode: CreativeMode.traceFruit,
    stickerRewardId: 'palette',
    guidePaths: _grapes(),
  ),
];

/// Looks up a guide by [id], or null for the free-draw sentinel / unknown ids.
TraceGuide? guideById(String id) {
  for (final TraceGuide g in kCreativeGuides) {
    if (g.id == id) return g;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Geometry helpers (all in the 100×100 viewBox).
// ---------------------------------------------------------------------------

TraceGuide _shapeGuide(
  String id,
  String emoji,
  ShapeKind kind,
  String stickerRewardId,
) {
  return TraceGuide(
    id: id,
    titleKey: 'shape_${kind.name}',
    emoji: emoji,
    mode: CreativeMode.traceShape,
    stickerRewardId: stickerRewardId,
    // pathFor pads 10% inside its box, so the shape sits comfortably centred.
    guidePaths: <Path>[ShapePainter.pathFor(kind, const Size(100, 100))],
  );
}

Path _oval(double l, double t, double w, double h) =>
    Path()..addOval(Rect.fromLTWH(l, t, w, h));

List<Path> _apple() {
  final Path body = Path()
    ..moveTo(50, 32)
    ..cubicTo(30, 22, 14, 38, 18, 58)
    ..cubicTo(20, 76, 38, 88, 50, 82)
    ..cubicTo(62, 88, 80, 76, 82, 58)
    ..cubicTo(86, 38, 70, 22, 50, 32)
    ..close();
  final Path stem = Path()
    ..moveTo(50, 32)
    ..lineTo(53, 18);
  final Path leaf = _oval(53, 14, 16, 9);
  return <Path>[body, stem, leaf];
}

List<Path> _banana() {
  final Path body = Path()
    ..moveTo(24, 50)
    ..cubicTo(26, 78, 50, 90, 78, 78)
    ..cubicTo(82, 76, 80, 70, 75, 72)
    ..cubicTo(54, 80, 36, 70, 34, 48)
    ..cubicTo(34, 44, 26, 44, 24, 50)
    ..close();
  return <Path>[body];
}

List<Path> _pear() {
  // A small top lobe blended into a larger bottom lobe.
  final Path body = Path()
    ..moveTo(50, 24)
    ..cubicTo(40, 24, 40, 40, 44, 50)
    ..cubicTo(34, 58, 30, 72, 40, 82)
    ..cubicTo(48, 90, 58, 90, 64, 80)
    ..cubicTo(72, 70, 66, 56, 56, 50)
    ..cubicTo(60, 40, 60, 24, 50, 24)
    ..close();
  final Path stem = Path()
    ..moveTo(50, 24)
    ..lineTo(52, 14);
  return <Path>[body, stem];
}

List<Path> _grapes() {
  // A pyramid cluster of berries with a stem and leaf.
  const double r = 8;
  const List<Offset> centers = <Offset>[
    Offset(50, 36),
    Offset(40, 48),
    Offset(60, 48),
    Offset(32, 60),
    Offset(50, 60),
    Offset(68, 60),
    Offset(42, 72),
    Offset(58, 72),
    Offset(50, 84),
  ];
  final List<Path> paths = <Path>[
    for (final Offset c in centers)
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
  ];
  paths.add(
    Path()
      ..moveTo(50, 36)
      ..lineTo(52, 22),
  );
  paths.add(_oval(52, 16, 14, 8));
  return paths;
}
