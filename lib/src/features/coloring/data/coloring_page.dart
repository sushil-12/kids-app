import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A coloring page definition loaded from the content manifest.
/// Line art + region metadata are authored offline (SVG -> region masks).
class ColoringPage extends Equatable {
  const ColoringPage({
    required this.id,
    required this.title,
    required this.category,
    required this.assetPath,
    required this.isPremium,
    required this.stickerRewardId,
  });

  final String id;
  final String title;
  final String category;
  final String assetPath; // line-art asset
  final bool isPremium;
  final String stickerRewardId;

  @override
  List<Object?> get props =>
      <Object?>[id, title, category, assetPath, isPremium];
}

/// A single freehand stroke the child paints onto the canvas.
/// Immutable so the undo stack can hold cheap snapshots.
class ColorStroke extends Equatable {
  const ColorStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  final Color color;
  final double width;
  final List<Offset> points;

  ColorStroke copyWith({List<Offset>? points}) =>
      ColorStroke(color: color, width: width, points: points ?? this.points);

  @override
  List<Object?> get props => <Object?>[color, width, points];
}
