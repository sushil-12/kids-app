import '../data/cinematic_story_v2.dart';

/// Fires a scene's [SceneCue]s as the [SceneClock] crosses their timestamps.
///
/// Pure and Flutter-free: it returns the cues that came due and lets the caller
/// dispatch them (play sfx, duck music, set a Rive input, move the camera). The
/// separation keeps the timing logic unit-testable and side-effect-free.
///
/// Two kinds of cue, split so that scrubbing/replaying never desyncs:
///
///  * **Transient** cues (sfx, dialogue audio, hold, music/ambient swells,
///    optional interactions) *happen* at a moment. On a normal forward tick
///    they fire once, in order.
///  * **Stateful** cues (character actions, prop changes, camera moves) *set*
///    on-stage state. On a seek we don't replay the transient ones — we
///    reconstruct state by applying the latest stateful cue at or before the
///    target time (`seekTo`), so jumping to t=5s shows the right poses without
///    re-playing five seconds of sound.
class CueScheduler {
  CueScheduler(List<SceneCue> cues)
    : _cues = List<SceneCue>.of(cues)
        ..sort((SceneCue a, SceneCue b) => a.t.compareTo(b.t));

  final List<SceneCue> _cues;

  /// Exclusive lower bound already dispatched. Starts below 0 so a cue at t=0
  /// fires on the first [advanceTo].
  double _cursor = -1;

  double get cursor => _cursor;

  /// Whether [cue] mutates persistent on-stage state (vs. a one-shot effect).
  static bool isStateful(SceneCue cue) =>
      cue is CharacterCue || cue is PropCue || cue is CameraCue;

  /// Rewind to the start (cursor before 0). Call on scene enter / replay.
  void reset() => _cursor = -1;

  /// Return every cue whose time is in `(cursor, t]`, in timeline order, and
  /// advance the cursor to [t]. Idempotent: calling again with the same or an
  /// earlier [t] yields nothing (use [seekTo] to jump backward).
  List<SceneCue> advanceTo(double t) {
    if (t <= _cursor) return const <SceneCue>[];
    final List<SceneCue> due = <SceneCue>[
      for (final SceneCue cue in _cues)
        if (cue.t > _cursor && cue.t <= t) cue,
    ];
    _cursor = t;
    return due;
  }

  /// Jump the cursor to [t] WITHOUT firing transient cues, and return only the
  /// stateful cues needed to rebuild the stage at [t] — the last stateful cue
  /// per target at or before [t] (plus every camera cue in order, since a
  /// camera move mid-flight still matters). Used by scrub / replay-from.
  List<SceneCue> seekTo(double t) {
    final Map<String, SceneCue> latestByTarget = <String, SceneCue>{};
    final List<CameraCue> cameras = <CameraCue>[];
    for (final SceneCue cue in _cues) {
      if (cue.t > t) break; // sorted — nothing further is in range
      switch (cue) {
        case CharacterCue(:final String target):
          latestByTarget['char:$target'] = cue;
        case PropCue(:final String target):
          latestByTarget['prop:$target'] = cue;
        case CameraCue():
          cameras.add(cue);
        default:
          break; // transient — skipped on seek
      }
    }
    _cursor = t;
    return <SceneCue>[...latestByTarget.values, ...cameras]
      ..sort((SceneCue a, SceneCue b) => a.t.compareTo(b.t));
  }
}
