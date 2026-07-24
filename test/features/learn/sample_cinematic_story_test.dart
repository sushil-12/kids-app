import 'package:brightmind_kids/src/features/learn/data/cinematic_story.dart';
import 'package:brightmind_kids/src/features/learn/data/sample_cinematic_story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sampleCinematicStoryFor', () {
    test('parses the English wire JSON into a playable story', () {
      final CinematicStory story = sampleCinematicStoryFor('en');

      expect(story.slug, 'hare-and-tortoise-en');
      expect(story.lang, 'en');
      expect(story.scenes, hasLength(5));
      // Cover + every scene carry an illustration URL (the exact host can
      // change as art is swapped in — assert presence, not a fixed path).
      expect(story.coverImage, isNotNull);
      expect(story.coverImage, startsWith('http'));
      for (final StoryScene scene in story.scenes) {
        expect(scene.image, isNotNull, reason: 'scene ${scene.id}');
        expect(scene.image, startsWith('http'), reason: 'scene ${scene.id}');
      }
      expect(story.scenes.first.interaction?.type, InteractionType.tap);
      expect(story.scenes[3].interaction?.type, InteractionType.drag);
      expect(story.scenes[3].interaction?.dropZone, 'flower');
      expect(
        story.scenes.expand((StoryScene s) => s.characters).every(
              (SceneCharacter c) =>
                  c.kind == CharacterKind.rabbit ||
                  c.kind == CharacterKind.turtle,
            ),
        isTrue,
      );
    });

    test('parses the Hindi wire JSON', () {
      final CinematicStory story = sampleCinematicStoryFor('hi');

      expect(story.slug, 'hare-and-tortoise-hi');
      expect(story.lang, 'hi');
      expect(story.scenes, hasLength(5));
      expect(story.moral, isNotEmpty);
    });

    test('any other language code falls back to English', () {
      expect(sampleCinematicStoryFor('fr').lang, 'en');
    });
  });
}
