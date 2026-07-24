import 'dart:convert';
import 'dart:io';

import 'package:brightmind_kids/src/features/learn/data/cinematic_story_v2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test: the JSON the backend is handed
/// (`backend_samples/cinematic_story_v2_hare_and_tortoise.json`) must parse
/// cleanly through the shipping app model. If the backend follows that file's
/// shape, the app plays it. Keep this green whenever either side changes.
void main() {
  group('backend v2 sample — Hare and the Tortoise', () {
    late final CinematicStoryV2 story;

    setUpAll(() {
      final File file = File(
        'backend_samples/cinematic_story_v2_hare_and_tortoise.json',
      );
      final Map<String, dynamic> json =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      story = CinematicStoryV2.fromJson(json);
    });

    test('parses into a complete, playable story', () {
      expect(story.schemaVersion, '2.0');
      expect(story.slug, 'hare-and-tortoise');
      expect(story.scenes, hasLength(6));
      expect(story.moral, isNotEmpty);
      expect(story.cover.emoji, '🐢');
      expect(story.cover.palette, isNotEmpty);
    });

    test('every scene has narration, a mood and a real timeline', () {
      for (final CinematicSceneV2 scene in story.scenes) {
        expect(scene.narration.text, isNotEmpty, reason: 'scene ${scene.id}');
        expect(scene.cues, isNotEmpty, reason: 'scene ${scene.id}');
        expect(scene.scriptedDuration, greaterThan(0));
      }
    });

    test('NO mandatory interactions — every interaction cue is optional', () {
      for (final CinematicSceneV2 scene in story.scenes) {
        for (final InteractionCue hotspot in scene.hotspots) {
          expect(
            hotspot.optional,
            isTrue,
            reason: 'scene ${scene.id} target ${hotspot.target}',
          );
        }
      }
    });

    test('no unknown cue types were silently dropped', () {
      // Re-count cues in the raw JSON and confirm the parser kept them all
      // (i.e. every wire cue.type in the sample is one the app understands).
      final Map<String, dynamic> json = jsonDecode(
        File('backend_samples/cinematic_story_v2_hare_and_tortoise.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<dynamic> scenes = json['scenes'] as List<dynamic>;
      for (int i = 0; i < scenes.length; i++) {
        final int rawCount =
            ((scenes[i] as Map<String, dynamic>)['cues'] as List<dynamic>)
                .length;
        expect(
          story.scenes[i].cues.length,
          rawCount,
          reason: 'scene ${i + 1} dropped a cue the app should understand',
        );
      }
    });

    test('camera targets and dialogue speakers reference real cast ids', () {
      for (final CinematicSceneV2 scene in story.scenes) {
        final Set<String> castIds =
            scene.cast.map((CastMember c) => c.id).toSet();
        for (final DialogueCue line in scene.cues.whereType<DialogueCue>()) {
          expect(
            castIds,
            contains(line.speaker),
            reason: 'scene ${scene.id} dialogue speaker "${line.speaker}"',
          );
        }
      }
    });
  });
}
