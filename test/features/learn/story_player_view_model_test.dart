import 'package:brightmind_kids/src/features/learn/data/cinematic_fallbacks.dart';
import 'package:brightmind_kids/src/features/learn/data/cinematic_story.dart';
import 'package:brightmind_kids/src/features/learn/view_model/story_player_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three scenes: tap interaction, no interaction, drag interaction.
const CinematicStory _story = CinematicStory(
  id: 'test',
  slug: 'test',
  title: 'Test Story',
  lang: 'en',
  ageBand: 'junior',
  coverEmoji: '📖',
  moral: 'Testing is caring.',
  reward: StoryReward(stars: 7, coins: 3, badgeStickerId: 'star'),
  scenes: <StoryScene>[
    StoryScene(
      id: 1,
      title: 'One',
      background: SceneBackground.sky,
      narration: 'Scene one.',
      props: <SceneProp>[
        SceneProp(id: 'sun', kind: PropKind.sun, x: 0.5, y: 0.2),
      ],
      interaction: SceneInteraction(
        type: InteractionType.tap,
        target: 'sun',
        hint: 'Tap the sun!',
      ),
    ),
    StoryScene(
      id: 2,
      title: 'Two',
      background: SceneBackground.forest,
      narration: 'Scene two.',
    ),
    StoryScene(
      id: 3,
      title: 'Three',
      background: SceneBackground.village,
      narration: 'Scene three.',
      props: <SceneProp>[
        SceneProp(id: 'pot', kind: PropKind.pot, x: 0.6, y: 0.7),
      ],
      characters: <SceneCharacter>[
        SceneCharacter(id: 'crow', kind: CharacterKind.crow, x: 0.3, y: 0.4),
      ],
      interaction: SceneInteraction(
        type: InteractionType.drag,
        target: 'crow',
        dropZone: 'pot',
        hint: 'Drag the crow!',
      ),
    ),
  ],
);

void main() {
  late ProviderContainer container;

  StoryPlayerState read() => container.read(storyPlayerProvider(_story));
  StoryPlayerViewModel vm() =>
      container.read(storyPlayerProvider(_story).notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts narrating the first scene', () {
    expect(read().sceneIndex, 0);
    expect(read().phase, PlayerPhase.narrating);
  });

  test('a scene with an interaction blocks on it after narration', () {
    vm().onNarrationComplete();
    expect(read().phase, PlayerPhase.interacting);
    expect(read().sceneIndex, 0, reason: 'must not advance until solved');
  });

  test('tapping the right target solves and advances', () {
    vm().onNarrationComplete();
    final bool solved = vm().tapTarget('sun');
    expect(solved, isTrue);
    expect(read().sceneIndex, 1);
    expect(read().phase, PlayerPhase.narrating);
  });

  test('wrong taps wobble but never fail or advance', () {
    vm().onNarrationComplete();
    expect(vm().tapTarget('moon'), isFalse);
    expect(vm().tapTarget(''), isFalse);
    expect(read().wrongTapTick, 2);
    expect(read().sceneIndex, 0);
    expect(read().phase, PlayerPhase.interacting);
  });

  test('taps are ignored while narrating (interaction gating)', () {
    expect(vm().tapTarget('sun'), isFalse);
    expect(read().wrongTapTick, 0);
    expect(read().sceneIndex, 0);
  });

  test('a scene without an interaction auto-advances after narration', () {
    vm().onNarrationComplete();
    vm().tapTarget('sun'); // → scene 2 (no interaction)
    vm().onNarrationComplete(); // → scene 3
    expect(read().sceneIndex, 2);
    expect(read().phase, PlayerPhase.narrating);
  });

  test('drag solves only with the right target on the right zone', () {
    vm().onNarrationComplete();
    vm().tapTarget('sun');
    vm().onNarrationComplete();
    vm().onNarrationComplete(); // scene 3 now interacting
    expect(read().phase, PlayerPhase.interacting);

    expect(vm().dropOnZone('crow', 'tree'), isFalse);
    expect(vm().dropOnZone('pot', 'pot'), isFalse);
    expect(read().phase, PlayerPhase.interacting);

    expect(vm().dropOnZone('crow', 'pot'), isTrue);
    expect(read().phase, PlayerPhase.finished);
  });

  test('finishing the last scene ends the story', () {
    vm().onNarrationComplete();
    vm().tapTarget('sun');
    vm().onNarrationComplete();
    vm().onNarrationComplete();
    vm().dropOnZone('crow', 'pot');
    expect(read().isFinished, isTrue);
  });

  test('skip advances past narration and stuck interactions', () {
    vm().skip(); // scene 0 → 1 even mid-narration
    expect(read().sceneIndex, 1);
    vm().skip();
    vm().onNarrationComplete(); // scene 3 interacting
    vm().skip(); // unblocks the drag
    expect(read().isFinished, isTrue);
  });

  test('replay restarts from the first scene', () {
    vm().skip();
    vm().skip();
    vm().skip();
    expect(read().isFinished, isTrue);

    vm().replay();
    expect(read().sceneIndex, 0);
    expect(read().phase, PlayerPhase.narrating);
  });

  test('bundled fallback stories parse-safe round trip', () {
    for (final CinematicStory story in <CinematicStory>[
      CinematicFallbacks.thirstyCrowEn,
      CinematicFallbacks.thirstyCrowHi,
    ]) {
      final CinematicStory decoded = CinematicStory.fromJson(story.toJson());
      expect(decoded.title, story.title);
      expect(decoded.scenes.length, story.scenes.length);
      expect(decoded.music, story.music);
      expect(decoded.reward.stars, story.reward.stars);
      expect(
        decoded.scenes[0].interaction?.target,
        story.scenes[0].interaction?.target,
      );
      expect(decoded.scenes[0].particles, story.scenes[0].particles);
    }
  });

  test('unknown wire vocabulary degrades to safe defaults', () {
    final CinematicStory story = CinematicStory.fromJson(<String, dynamic>{
      'title': 'Future Story',
      'music': 'synthwave',
      'scenes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'title': 'X',
          'background': 'beach',
          'narration': 'Hello.',
          'camera': <String, dynamic>{'effect': 'dolly_zoom'},
          'props': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'p', 'kind': 'spaceship', 'x': 0.5, 'y': 0.5},
          ],
          'characters': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'c', 'kind': 'dinosaur', 'x': 0.5, 'y': 0.5, 'animation': 'moonwalk'},
          ],
          'particles': <String>['confetti', 'stars'],
        },
      ],
    });

    expect(story.music, MusicTrack.calm);
    final StoryScene scene = story.scenes[0];
    expect(scene.background, SceneBackground.sky);
    expect(scene.camera, CameraEffect.none);
    expect(scene.props[0].kind, PropKind.cloud);
    expect(scene.characters[0].kind, CharacterKind.bird);
    expect(scene.characters[0].animation, CharacterAnimation.idle);
    expect(scene.particles, <ParticleKind>[ParticleKind.stars]);
  });
}
