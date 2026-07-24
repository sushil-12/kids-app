import 'dart:math' as math;

/// The playhead for one scene.
///
/// A deliberately pure, Flutter-free class so it can be unit-tested without a
/// vsync: the view owns a [Ticker]/[AnimationController] and pumps real
/// wall-clock deltas into [advance]; everything else in the engine
/// ([CueScheduler], [CameraRig], narration highlight) samples this one clock,
/// so pause / resume / seek / speed come for free and stay in perfect sync.
///
/// `t` is seconds since the scene began. [duration] is the scene's *scripted
/// floor* (`CinematicSceneV2.scriptedDuration`); it is only used by
/// [reachedFloor] — narration finishing later can still hold the scene open,
/// which is the director's job, not the clock's.
class SceneClock {
  SceneClock({double duration = 0}) : _duration = math.max(0, duration);

  double _t = 0;
  double _duration;
  double _speed = 1;
  bool _playing = false;

  /// Current playhead, in seconds (>= 0, clamped to [duration] when it has one).
  double get t => _t;

  bool get isPlaying => _playing;
  double get speed => _speed;
  double get duration => _duration;

  set duration(double value) => _duration = math.max(0, value);

  /// True once the playhead has reached the scripted floor. A scene with no
  /// floor (`duration == 0`) is considered to have reached it immediately.
  bool get reachedFloor => _duration <= 0 || _t >= _duration;

  void play() => _playing = true;
  void pause() => _playing = false;

  /// Clamp playback rate to a child-safe band (0.5×–2×).
  void setSpeed(double value) => _speed = value.clamp(0.5, 2.0);

  /// Jump to [seconds] without changing play/pause. Clamped to [0, duration]
  /// (or just >= 0 when there is no duration). Callers reconstruct scene state
  /// via [CueScheduler.seekTo] — the clock only moves the playhead.
  void seek(double seconds) {
    final double upper = _duration > 0 ? _duration : double.infinity;
    _t = seconds.clamp(0.0, upper).toDouble();
  }

  /// Restart the playhead at 0 (does not change play/pause).
  void reset() => _t = 0;

  /// Advance by a real wall-clock delta (seconds). No-op while paused. Returns
  /// the new [t]. The playhead is clamped at [duration] but the clock does NOT
  /// auto-pause there — the director decides when to leave the scene, because
  /// narration may still be speaking past the floor.
  double advance(double wallDeltaSeconds) {
    if (!_playing || wallDeltaSeconds <= 0) return _t;
    _t += wallDeltaSeconds * _speed;
    if (_duration > 0 && _t > _duration) _t = _duration;
    return _t;
  }
}
