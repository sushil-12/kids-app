import 'package:flutter/material.dart';

import '../../shared/shape_view.dart';

/// One item in a pattern: a colored shape. Patterns are built by repeating a
/// short run of these (e.g. circle-square-circle-square …) and asking the child
/// which element comes next.
///
/// Value equality lets the view-model compare elements when picking distractors
/// and when checking the tapped answer.
@immutable
class PatternElement {
  const PatternElement(this.kind, this.color);

  final ShapeKind kind;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is PatternElement && other.kind == kind && other.color == color;

  @override
  int get hashCode => Object.hash(kind, color);
}
