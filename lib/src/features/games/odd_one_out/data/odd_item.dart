import 'package:flutter/material.dart';

import '../../shared/shape_view.dart';

/// One tile in Odd-One-Out: a colored shape. A round shows several identical
/// items and exactly one that differs (in shape, color, or both).
///
/// Value equality is handy for tests and for asserting the odd tile really is
/// the only one unlike its neighbours.
@immutable
class OddItem {
  const OddItem(this.kind, this.color);

  final ShapeKind kind;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is OddItem && other.kind == kind && other.color == color;

  @override
  int get hashCode => Object.hash(kind, color);
}
