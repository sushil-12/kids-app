import 'package:brightmind_kids/src/features/learn/data/cinematic_story_v2.dart';
import 'package:brightmind_kids/src/features/learn/view_model/story_director_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CinematicStoryV2 _story({int scenes = 3}) => CinematicStoryV2(
      id: 's',
      slug: 's',
      title: 'S',
      lang: 'en',
      ageBand: 'junior',
      moral: 'm',
      scenes: <CinematicSceneV2>[
        for (int i = 0; i < scenes; i++)
          CinematicSceneV2(
            id: i + 1,
            title: 'Scene ${i + 1}',
            narration: Narration(text: 'n$i'),
          ),
      ],
    );

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  StoryDirectorViewModel vmFor(CinematicStoryV2 story) =>
      container.read(storyDirectorProvider(story).notifier);
  PlaybackState stateFor(CinematicStoryV2 story) =>
      container.read(storyDirectorProvider(story));

  group('StoryDirectorViewModel', () {
    test('starts on the cover for a non-empty story', () {
      final CinematicStoryV2 story = _story();
      expect(stateFor(story).status, PlaybackStatus.cover);
      expect(stateFor(story).sceneIndex, 0);
    });

    test('an empty story starts ended', () {
      final CinematicStoryV2 story = _story(scenes: 0);
      expect(stateFor(story).status, PlaybackStatus.ended);
    });

    test('begin leaves the cover and plays', () {
      final CinematicStoryV2 story = _story();
      vmFor(story).begin();
      expect(stateFor(story).status, PlaybackStatus.playing);
    });

    test('advance walks scenes then ends after the last', () {
      final CinematicStoryV2 story = _story(scenes: 2);
      final StoryDirectorViewModel vm = vmFor(story)..begin();
      vm.advance();
      expect(stateFor(story).sceneIndex, 1);
      expect(stateFor(story).status, PlaybackStatus.playing);
      vm.advance();
      expect(stateFor(story).status, PlaybackStatus.ended);
      // Advancing past the end is a no-op.
      vm.advance();
      expect(stateFor(story).status, PlaybackStatus.ended);
    });

    test('togglePause flips playing<->paused only', () {
      final CinematicStoryV2 story = _story();
      final StoryDirectorViewModel vm = vmFor(story)..begin();
      vm.togglePause();
      expect(stateFor(story).status, PlaybackStatus.paused);
      vm.togglePause();
      expect(stateFor(story).status, PlaybackStatus.playing);
    });

    test('togglePause does nothing on the cover or end card', () {
      final CinematicStoryV2 story = _story();
      final StoryDirectorViewModel vm = vmFor(story);
      vm.togglePause(); // still on cover
      expect(stateFor(story).status, PlaybackStatus.cover);
      vm.end();
      vm.togglePause(); // ended
      expect(stateFor(story).status, PlaybackStatus.ended);
    });

    test('replay restarts at scene 0, playing', () {
      final CinematicStoryV2 story = _story(scenes: 2);
      final StoryDirectorViewModel vm = vmFor(story)
        ..begin()
        ..advance()
        ..advance();
      expect(stateFor(story).status, PlaybackStatus.ended);
      vm.replay();
      expect(stateFor(story).sceneIndex, 0);
      expect(stateFor(story).status, PlaybackStatus.playing);
    });

    test('skip is equivalent to a natural scene finish', () {
      final CinematicStoryV2 story = _story(scenes: 2);
      final StoryDirectorViewModel vm = vmFor(story)..begin();
      vm.skip();
      expect(stateFor(story).sceneIndex, 1);
    });
  });
}
