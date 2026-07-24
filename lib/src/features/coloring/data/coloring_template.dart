import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

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
    required this.stickerRewardId,
    this.details = const <Path>[],
    this.isPremium = false,
    this.byNumber = const <String, int>{},
  });

  /// Builds a template from the backend wire format (see
  /// `kids-app-backend` `/v1/coloring`). Every `d` is an SVG path string parsed
  /// straight into a Flutter [Path], so a downloaded page renders through the
  /// exact same painter as a bundled one. Throws on malformed JSON/paths — the
  /// caller skips bad pages so one dud never breaks the gallery.
  factory ColoringTemplate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> regionsJson = json['regions'] as List<dynamic>;
    final List<ColorRegion> regions = <ColorRegion>[];
    final Map<String, int> byNumber = <String, int>{};
    for (final dynamic r in regionsJson) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      final String id = m['id'] as String;
      regions
          .add(ColorRegion(id: id, path: parseSvgPathData(m['d'] as String)));
      final Object? bn = m['byNumber'];
      if (bn is num) byNumber[id] = bn.toInt();
    }
    List<Path> parsePaths(Object? raw) => <Path>[
          for (final dynamic d in (raw as List<dynamic>? ?? const <dynamic>[]))
            parseSvgPathData(d as String),
        ];
    final String id = json['id'] as String;
    return ColoringTemplate(
      id: id,
      title: json['title'] as String,
      viewBox: (json['viewBox'] as num).toDouble(),
      isPremium: json['isPremium'] as bool? ?? false,
      stickerRewardId: json['stickerRewardId'] as String? ?? id,
      regions: regions,
      outlines: parsePaths(json['outlines']),
      details: parsePaths(json['details']),
      byNumber: byNumber,
    );
  }

  final String id;
  final String title;
  final double viewBox;
  final List<ColorRegion> regions;
  final List<Path> outlines;
  final List<Path> details;
  final bool isPremium;

  /// Id of the sticker (in `kStickers`) awarded for finishing this picture, so
  /// each page unlocks a themed reward (e.g. the fish page → the fish sticker).
  final String stickerRewardId;

  /// Color-by-Number key: region id → 1-based palette number (see
  /// `kByNumberPalette`). Empty means the picture has no by-number mode.
  final Map<String, int> byNumber;

  /// Whether this picture can be played in Color-by-Number mode.
  bool get supportsByNumber => byNumber.isNotEmpty;

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
