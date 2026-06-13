import 'package:flutter/widgets.dart';

/// A single fillable area of a coloring picture (e.g. the sun's body).
/// Paths are authored in a square viewBox coordinate space (see
/// [ColoringTemplate.viewBox]) so the picture scales crisply to any size.
@immutable
class ColorRegion {
  const ColorRegion({required this.id, required this.path});

  final String id;
  final Path path;
}

/// A complete coloring picture, defined as vector geometry.
///
/// * [regions]   – fillable areas, ordered back-to-front. Hit-testing walks
///                 them front-to-back so the top-most shape wins a tap.
/// * [outlines]  – stroked black line art drawn on top of the fills.
/// * [details]   – small solid-black shapes (eyes, knobs) drawn last.
@immutable
class ColoringTemplate {
  const ColoringTemplate({
    required this.id,
    required this.title,
    required this.viewBox,
    required this.regions,
    required this.outlines,
    this.details = const <Path>[],
    this.isPremium = false,
  });

  final String id;
  final String title;
  final double viewBox;
  final List<ColorRegion> regions;
  final List<Path> outlines;
  final List<Path> details;
  final bool isPremium;

  /// Finds the top-most region containing [logicalPoint], or null.
  String? hitTest(Offset logicalPoint) {
    for (int i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(logicalPoint)) return regions[i].id;
    }
    return null;
  }
}

/// Maps between screen pixels and the template's logical viewBox space.
/// The SAME instance math is used by the painter and the gesture layer, so
/// what a child taps is exactly what gets painted.
@immutable
class CanvasFit {
  const CanvasFit(this.scale, this.offset);

  final double scale;
  final Offset offset;

  factory CanvasFit.of(Size size, double viewBox) {
    final double scale = size.shortestSide / viewBox;
    final double dx = (size.width - viewBox * scale) / 2;
    final double dy = (size.height - viewBox * scale) / 2;
    return CanvasFit(scale, Offset(dx, dy));
  }

  Offset toLogical(Offset local) =>
      Offset((local.dx - offset.dx) / scale, (local.dy - offset.dy) / scale);
}
