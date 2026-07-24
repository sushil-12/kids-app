import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../data/cinematic_story_v2.dart';

/// The virtual camera's state at one instant: a uniform [scale] (zoom about the
/// stage centre) plus a [offset] translation expressed in *fractions of the
/// stage size*. Renderer-agnostic — the same frame drives the vector
/// CustomPainter stage or a full-bleed illustration.
@immutable
class CameraFrame {
  const CameraFrame({this.scale = 1, this.offset = Offset.zero});

  final double scale;
  final Offset offset;

  static const CameraFrame identity = CameraFrame();

  /// Concrete transform for a stage of [size]: translate by the fractional
  /// offset, then zoom about the centre (matching the existing player's
  /// `Transform.translate` ∘ `Transform.scale`).
  Matrix4 toMatrix4(Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    return Matrix4.identity()
      ..translateByDouble(offset.dx * size.width, offset.dy * size.height, 0, 1)
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}

/// Turns a keyframed [SceneCamera] into a [CameraFrame] for a given playhead
/// time. Stateless and pure, so it's trivially unit-tested and can be sampled
/// every frame off the [SceneClock].
class CameraRig {
  const CameraRig();

  /// Sample the camera at [t] seconds. [resolveTarget] maps a cast/prop id to
  /// its fractional stage position (0..1, where 0.5,0.5 is centre) so the rig
  /// can push in on a character; return null for unknown/unpositioned ids.
  CameraFrame frameAt(
    SceneCamera? camera,
    double t, {
    Offset Function(String id)? resolveTarget,
  }) {
    if (camera == null) return CameraFrame.identity;

    // Eased progress through the move, clamped so before startAt we sit on
    // `from` and after the move we hold on `to`.
    final double raw = camera.duration <= 0
        ? 1.0
        : ((t - camera.startAt) / camera.duration).clamp(0.0, 1.0);
    final double p = _curveFor(camera.ease).transform(raw);

    final double zoom =
        lerpDouble(camera.from.zoom, camera.to.zoom, p) ?? camera.to.zoom;

    // Authored Ken Burns drift.
    Offset offset = Offset.lerp(camera.from.offset, camera.to.offset, p)!;

    // Target follow: bias the frame so the focused point sits at centre. We
    // interpolate the follow bias between the two keyframes' targets so a move
    // can hand off focus (e.g. from a wide point to a character).
    final Offset? fromFollow = _follow(camera.from.targetId, zoom, resolveTarget);
    final Offset? toFollow = _follow(camera.to.targetId, zoom, resolveTarget);
    if (fromFollow != null || toFollow != null) {
      final Offset a = fromFollow ?? toFollow!;
      final Offset b = toFollow ?? fromFollow!;
      offset += Offset.lerp(a, b, p)!;
    }

    return CameraFrame(scale: zoom, offset: offset);
  }

  /// Fractional translation that brings [id]'s position to the stage centre
  /// under [zoom]. Null when there's no target or it can't be resolved.
  Offset? _follow(
    String? id,
    double zoom,
    Offset Function(String id)? resolveTarget,
  ) {
    if (id == null || resolveTarget == null) return null;
    final Offset pos = resolveTarget(id);
    // Distance of the target from centre, in fractional units. Scaling about
    // the centre magnifies that distance by `zoom`, so we translate it back.
    final Offset rel = pos - const Offset(0.5, 0.5);
    return -rel * zoom;
  }

  Curve _curveFor(CameraEase ease) => switch (ease) {
    CameraEase.linear => Curves.linear,
    CameraEase.easeIn => Curves.easeIn,
    CameraEase.easeOut => Curves.easeOut,
    CameraEase.easeInOut => Curves.easeInOut,
    CameraEase.easeInOutSine => Curves.easeInOutSine,
    CameraEase.easeOutBack => Curves.easeOutBack,
  };
}
