import 'package:brightmind_kids/src/features/learn/data/cinematic_story.dart';
import 'package:brightmind_kids/src/features/learn/data/cinematic_story_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CinematicStoryV2 parsing', () {
    test('minimal payload fills safe defaults', () {
      final CinematicStoryV2 story =
          CinematicStoryV2.fromJson(<String, dynamic>{
        'id': 's1',
        'slug': 'x',
        'title': 'X',
        'scenes': <dynamic>[
          <String, dynamic>{
            'id': 1,
            'title': 'A',
            'narration': 'Once upon a time.',
          },
        ],
      });

      expect(story.schemaVersion, '2.0');
      expect(story.lang, 'en');
      expect(story.scenes.single.narration.text, 'Once upon a time.');
      expect(story.scenes.single.mood, SceneMood.calm);
      expect(story.scenes.single.camera, isNull);
      expect(story.scenes.single.cues, isEmpty);
    });

    test('narration accepts a bare string OR a rich object', () {
      final CinematicSceneV2 fromString =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': 'plain text',
      });
      expect(fromString.narration.text, 'plain text');
      expect(fromString.narration.hasWordTiming, isFalse);

      final CinematicSceneV2 fromObject =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': <String, dynamic>{
          'text': 'timed text',
          'granularity': 'word',
          'marks': <dynamic>[
            <String, dynamic>{'w': 'timed', 't': 0.5},
            <String, dynamic>{'w': 'text', 't': 0.9},
          ],
        },
      });
      expect(fromObject.narration.hasWordTiming, isTrue);
      expect(fromObject.narration.marks.first.word, 'timed');
      expect(fromObject.narration.marks.last.t, 0.9);
    });

    test('unknown enum values degrade to safe defaults (forward compat)', () {
      final CinematicSceneV2 scene =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': 'n',
        'mood': 'apocalyptic',
        'background': 'mars',
        'stage': <String, dynamic>{'renderer': 'holograph'},
      });
      expect(scene.mood, SceneMood.calm);
      expect(scene.background, SceneBackground.sky);
      expect(scene.stage.renderer, StageRenderer.vector);
    });

    test('unknown cue types are skipped, known ones parse in time order', () {
      final CinematicSceneV2 scene =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': 'n',
        'cues': <dynamic>[
          <String, dynamic>{'type': 'hold', 't': 5, 'duration': 1.5},
          <String, dynamic>{'type': 'time_travel', 't': 2},
          <String, dynamic>{
            'type': 'dialogue',
            't': 1,
            'speaker': 'hare',
            'text': 'Hi!',
          },
          <String, dynamic>{'type': 'sfx', 't': 3, 'sound': 'giggle'},
        ],
      });

      expect(scene.cues, hasLength(3)); // time_travel dropped
      expect(scene.cues.map((SceneCue c) => c.t), <double>[1, 3, 5]);
      expect(scene.cues.first, isA<DialogueCue>());
    });

    test('scriptedDuration = max(minDuration, last cue end); ignores hotspots',
        () {
      final CinematicSceneV2 scene =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': 'n',
        'minDuration': 8,
        'cues': <dynamic>[
          // hold ends at 6.5 — below the floor.
          <String, dynamic>{'type': 'hold', 't': 5, 'duration': 1.5},
          // an optional hotspot at t=20 must NOT extend the scene.
          <String, dynamic>{
            'type': 'interaction',
            't': 20,
            'target': 'butterfly',
          },
        ],
      });
      expect(scene.scriptedDuration, 8);
      expect(scene.hotspots, hasLength(1));

      final CinematicSceneV2 longer =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 2,
        'title': 'B',
        'narration': 'n',
        'minDuration': 8,
        'cues': <dynamic>[
          <String, dynamic>{'type': 'hold', 't': 9, 'duration': 2},
        ],
      });
      expect(longer.scriptedDuration, 11); // 9 + 2 hold span
    });

    test('camera cue defaults its move startAt to the cue time', () {
      final CinematicSceneV2 scene =
          CinematicSceneV2.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'A',
        'narration': 'n',
        'cues': <dynamic>[
          <String, dynamic>{
            'type': 'camera',
            't': 4,
            'move': <String, dynamic>{
              'to': <String, dynamic>{'zoom': 1.4},
              'duration': 3,
            },
          },
        ],
      });
      final CameraCue cue = scene.cues.single as CameraCue;
      expect(cue.move.startAt, 4);
      expect(cue.move.to.zoom, 1.4);
    });

    test('full round-trip through toJson/fromJson preserves the timeline', () {
      const CinematicStoryV2 story = CinematicStoryV2(
        id: 's1',
        slug: 'hare',
        title: 'Hare',
        lang: 'en',
        ageBand: 'junior',
        moral: 'Slow and steady wins the race.',
        cover: StoryCover(emoji: '🐢', palette: <String>['#2EBDB5']),
        scenes: <CinematicSceneV2>[
          CinematicSceneV2(
            id: 1,
            title: 'The Boast',
            narration: Narration(text: 'The hare bragged.'),
            camera: SceneCamera(
              from: CameraKeyframe(targetId: 'hare', zoom: 1.1),
              to: CameraKeyframe(targetId: 'hare', zoom: 1.35),
              duration: 5,
              ease: CameraEase.easeInOutSine,
              startAt: 1.5,
            ),
            cast: <CastMember>[
              CastMember(
                id: 'hare',
                kind: CharacterKind.rabbit,
                x: 0.4,
                y: 0.6,
                emotion: Emotion.proud,
              ),
            ],
            cues: <SceneCue>[
              DialogueCue(
                t: 3,
                speaker: 'hare',
                text: 'I am the fastest!',
                emotion: Emotion.proud,
              ),
              HoldCue(t: 7, duration: 1.5),
              InteractionCue(t: 0, target: 'butterfly'),
            ],
          ),
        ],
      );

      final CinematicStoryV2 decoded =
          CinematicStoryV2.fromJson(story.toJson());

      expect(decoded.scenes.single.camera!.ease, CameraEase.easeInOutSine);
      expect(decoded.scenes.single.cast.single.emotion, Emotion.proud);
      // Cues sort by time, so the t=0 hotspot leads; the dialogue survives too.
      expect(decoded.scenes.single.cues.first, isA<InteractionCue>());
      final DialogueCue line =
          decoded.scenes.single.cues.whereType<DialogueCue>().single;
      expect(line.text, 'I am the fastest!');
      expect(decoded.scenes.single.hotspots.single.optional, isTrue);
      expect(decoded.cover.palette.single, '#2EBDB5');
    });
  });
}
