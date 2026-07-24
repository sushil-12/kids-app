import 'dart:ui' show Offset, Size;

import 'package:flutter/widgets.dart' show MatrixUtils;

import 'package:brightmind_kids/src/features/learn/data/cinematic_story_v2.dart';
import 'package:brightmind_kids/src/features/learn/engine/camera_rig.dart';
import 'package:brightmind_kids/src/features/learn/engine/cue_scheduler.dart';
import 'package:brightmind_kids/src/features/learn/engine/scene_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SceneClock', () {
    test('advances only while playing, scaled by speed', () {
      final SceneClock clock = SceneClock(duration: 10);
      expect(clock.advance(1), 0); // paused → no move
      clock.play();
      clock.advance(1);
      expect(clock.t, 1);
      clock.setSpeed(2);
      clock.advance(1);
      expect(clock.t, 3); // +1 * 2
    });

    test('clamps at duration but does not auto-pause (director decides)', () {
      final SceneClock clock = SceneClock(duration: 5)..play();
      clock.advance(100);
      expect(clock.t, 5);
      expect(clock.reachedFloor, isTrue);
      expect(clock.isPlaying, isTrue);
    });

    test('speed is clamped to a child-safe band', () {
      final SceneClock clock = SceneClock();
      clock.setSpeed(10);
      expect(clock.speed, 2.0);
      clock.setSpeed(0.1);
      expect(clock.speed, 0.5);
    });

    test('seek clamps into range; reset returns to zero', () {
      final SceneClock clock = SceneClock(duration: 8)..play();
      clock.seek(20);
      expect(clock.t, 8);
      clock.seek(-3);
      expect(clock.t, 0);
      clock.advance(2);
      clock.reset();
      expect(clock.t, 0);
    });
  });

  group('CueScheduler', () {
    List<SceneCue> cues() => <SceneCue>[
      const InteractionCue(t: 0, target: 'butterfly'),
      const DialogueCue(t: 1, speaker: 'hare', text: 'Hi'),
      const CharacterCue(t: 2, target: 'hare', action: CharacterAction.hop),
      const SfxCue(t: 3, sound: 'giggle'),
      const CharacterCue(t: 4, target: 'hare', action: CharacterAction.run),
      const HoldCue(t: 5, duration: 1),
    ];

    test('fires cues once as the playhead crosses them, in order', () {
      final CueScheduler scheduler = CueScheduler(cues());
      final List<SceneCue> firstTick = scheduler.advanceTo(2.5);
      // t=0 (interaction), 1 (dialogue), 2 (character) are due.
      expect(firstTick.map((SceneCue c) => c.t), <double>[0, 1, 2]);

      // Re-asking with the same t yields nothing (idempotent).
      expect(scheduler.advanceTo(2.5), isEmpty);

      final List<SceneCue> next = scheduler.advanceTo(4);
      expect(next.map((SceneCue c) => c.t), <double>[3, 4]);
    });

    test('advanceTo backward is a no-op (use seekTo to jump back)', () {
      final CueScheduler scheduler = CueScheduler(cues());
      scheduler.advanceTo(5);
      expect(scheduler.advanceTo(2), isEmpty);
      expect(scheduler.cursor, 5);
    });

    test('seekTo rebuilds state (latest stateful cue) without transients', () {
      final CueScheduler scheduler = CueScheduler(cues());
      final List<SceneCue> state = scheduler.seekTo(4.5);

      // No dialogue/sfx/hold/interaction — only the character state survives,
      // and only the LATEST action for 'hare' (run at t=4, not hop at t=2).
      expect(state, hasLength(1));
      final CharacterCue survivor = state.single as CharacterCue;
      expect(survivor.action, CharacterAction.run);
      expect(scheduler.cursor, 4.5);

      // After a seek, forward advance resumes from the new cursor.
      expect(scheduler.advanceTo(5).single, isA<HoldCue>());
    });

    test('reset rewinds so a t=0 cue fires again on replay', () {
      final CueScheduler scheduler = CueScheduler(cues());
      scheduler.advanceTo(10);
      scheduler.reset();
      final List<SceneCue> replay = scheduler.advanceTo(0.5);
      expect(replay.single, isA<InteractionCue>());
    });
  });

  group('CameraRig', () {
    const CameraRig rig = CameraRig();
    const Size stage = Size(400, 800);

    test('null camera → identity frame', () {
      final CameraFrame f = rig.frameAt(null, 3);
      expect(f.scale, 1);
      expect(f.offset, Offset.zero);
    });

    test('zoom interpolates from → to across the move window', () {
      const SceneCamera cam = SceneCamera(
        from: CameraKeyframe(zoom: 1),
        to: CameraKeyframe(zoom: 2),
        duration: 4,
        ease: CameraEase.linear,
        startAt: 0,
      );
      expect(rig.frameAt(cam, 0).scale, 1);
      expect(rig.frameAt(cam, 2).scale, closeTo(1.5, 1e-9));
      expect(rig.frameAt(cam, 4).scale, 2);
      expect(rig.frameAt(cam, 99).scale, 2); // holds on `to` after the move
    });

    test('before startAt the frame sits on `from`', () {
      const SceneCamera cam = SceneCamera(
        from: CameraKeyframe(zoom: 1),
        to: CameraKeyframe(zoom: 2),
        duration: 2,
        ease: CameraEase.linear,
        startAt: 3,
      );
      expect(rig.frameAt(cam, 1).scale, 1);
    });

    test('target follow centres the focused point', () {
      // Target sits at the top-left-ish (0.25, 0.25); at zoom 1 the rig should
      // translate it toward centre by -(pos - centre).
      const SceneCamera cam = SceneCamera(
        from: CameraKeyframe(targetId: 'hare', zoom: 1),
        to: CameraKeyframe(targetId: 'hare', zoom: 1),
        duration: 1,
        ease: CameraEase.linear,
        startAt: 0,
      );
      final CameraFrame f = rig.frameAt(
        cam,
        1,
        resolveTarget: (String id) => const Offset(0.25, 0.25),
      );
      // rel = (0.25-0.5) = -0.25; follow = -rel*zoom = +0.25.
      expect(f.offset.dx, closeTo(0.25, 1e-9));
      expect(f.offset.dy, closeTo(0.25, 1e-9));
    });

    test('toMatrix4 keeps the stage centre fixed under zoom', () {
      const CameraFrame f = CameraFrame(scale: 2);
      final Offset centre = MatrixUtils.transformPoint(
        f.toMatrix4(stage),
        stage.center(Offset.zero),
      );
      expect(centre.dx, closeTo(stage.width / 2, 1e-6));
      expect(centre.dy, closeTo(stage.height / 2, 1e-6));
    });
  });
}
