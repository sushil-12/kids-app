import 'package:brightmind_kids/src/features/learn/data/cinematic_story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CinematicStory illustration fields', () {
    test('default to null on payloads without them (older backend)', () {
      final CinematicStory story = CinematicStory.fromJson(<String, dynamic>{
        'id': 's1',
        'slug': 'x',
        'title': 'X',
        'scenes': <dynamic>[
          <String, dynamic>{'id': 1, 'title': 'A', 'narration': 'n'},
        ],
      });

      expect(story.coverImage, isNull);
      expect(story.scenes.single.image, isNull);
    });

    test('round-trip through toJson/fromJson', () {
      const CinematicStory story = CinematicStory(
        id: 's1',
        slug: 'x',
        title: 'X',
        lang: 'en',
        ageBand: 'junior',
        coverEmoji: '📖',
        coverImage: 'https://cdn.example.com/cover.png',
        moral: 'm',
        scenes: <StoryScene>[
          StoryScene(
            id: 1,
            title: 'A',
            background: SceneBackground.forest,
            narration: 'n',
            image: 'https://cdn.example.com/scene-1.png',
          ),
        ],
      );

      final CinematicStory decoded = CinematicStory.fromJson(story.toJson());

      expect(decoded.coverImage, 'https://cdn.example.com/cover.png');
      expect(decoded.scenes.single.image, 'https://cdn.example.com/scene-1.png');
    });
  });
}
