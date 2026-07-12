import 'cinematic_story.dart';

/// Bundled offline cinematic story (The Thirsty Crow, en + hi) — the safety
/// net when the backend is unreachable or unconfigured, mirroring the
/// backend's seed content so the player behaves identically either way.
abstract final class CinematicFallbacks {
  /// The fallback story for a language code ('hi' → Hindi, anything else → en).
  static CinematicStory storyFor(String lang) =>
      lang == 'hi' ? thirstyCrowHi : thirstyCrowEn;

  static const CinematicStory thirstyCrowEn = CinematicStory(
    id: 'offline-thirsty-crow-en',
    slug: 'thirsty-crow-en',
    title: 'The Thirsty Crow',
    lang: 'en',
    ageBand: 'junior',
    coverEmoji: '🐦‍⬛',
    music: MusicTrack.forest,
    moral: 'Where there is a will, there is a way.',
    reward: StoryReward(stars: 10, coins: 5, badgeStickerId: 'star'),
    scenes: <StoryScene>[
      StoryScene(
        id: 1,
        title: 'A Hot Day',
        background: SceneBackground.hotDay,
        narration:
            'One day the sun was shining very, very hot. A little crow flew '
            'across the sky, looking for water.',
        camera: CameraEffect.zoomIn,
        props: <SceneProp>[
          SceneProp(id: 'sun', kind: PropKind.sun, x: 0.78, y: 0.16, scale: 1.2),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.35,
            y: 0.45,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.sunRays, ParticleKind.wind],
        interaction: SceneInteraction(
          type: InteractionType.tap,
          target: 'sun',
          hint: 'Touch the hot sun!',
          sound: 'chime',
        ),
      ),
      StoryScene(
        id: 2,
        title: 'Looking for Water',
        background: SceneBackground.village,
        narration:
            'The crow was so thirsty. He looked here and he looked there, '
            'but he could not find any water.',
        camera: CameraEffect.panRight,
        props: <SceneProp>[
          SceneProp(id: 'house', kind: PropKind.house, x: 0.2, y: 0.68),
          SceneProp(id: 'tree', kind: PropKind.tree, x: 0.82, y: 0.6, scale: 1.1),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.42,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.wind],
      ),
      StoryScene(
        id: 3,
        title: 'The Pot',
        background: SceneBackground.village,
        narration:
            'Then he saw a pot under a tree! Can you help the crow fly to '
            'the pot?',
        camera: CameraEffect.zoomIn,
        props: <SceneProp>[
          SceneProp(id: 'tree', kind: PropKind.tree, x: 0.75, y: 0.55, scale: 1.2),
          SceneProp(id: 'pot', kind: PropKind.pot, x: 0.6, y: 0.78),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(id: 'crow', kind: CharacterKind.crow, x: 0.2, y: 0.4),
        ],
        particles: <ParticleKind>[ParticleKind.birds],
        interaction: SceneInteraction(
          type: InteractionType.drag,
          target: 'crow',
          dropZone: 'pot',
          hint: 'Take the crow to the pot!',
          sound: 'plop',
        ),
      ),
      StoryScene(
        id: 4,
        title: 'Clever Pebbles',
        minDuration: 9,
        background: SceneBackground.village,
        narration:
            'The water was too low to reach. So the clever crow dropped '
            'little pebbles into the pot, one by one, and the water rose up '
            'and up!',
        props: <SceneProp>[
          SceneProp(id: 'pot', kind: PropKind.pot, x: 0.5, y: 0.72, scale: 1.3),
          SceneProp(id: 'rock', kind: PropKind.rock, x: 0.25, y: 0.82, scale: 0.8),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.45,
            animation: CharacterAnimation.bounce,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.bubbles],
      ),
      StoryScene(
        id: 5,
        title: 'A Happy Ending',
        background: SceneBackground.sky,
        narration:
            'The crow drank the cool water and flew away happy. When '
            'something is hard, think and try — where there is a will, there '
            'is a way!',
        camera: CameraEffect.zoomOut,
        props: <SceneProp>[
          SceneProp(id: 'sun', kind: PropKind.sun, x: 0.8, y: 0.15),
          SceneProp(id: 'cloud', kind: PropKind.cloud, x: 0.25, y: 0.2),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.4,
            scale: 1.1,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.birds, ParticleKind.wind],
      ),
    ],
  );

  static const CinematicStory thirstyCrowHi = CinematicStory(
    id: 'offline-thirsty-crow-hi',
    slug: 'thirsty-crow-hi',
    title: 'प्यासा कौआ',
    lang: 'hi',
    ageBand: 'junior',
    coverEmoji: '🐦‍⬛',
    music: MusicTrack.forest,
    moral: 'जहाँ चाह, वहाँ राह।',
    reward: StoryReward(stars: 10, coins: 5, badgeStickerId: 'star'),
    scenes: <StoryScene>[
      StoryScene(
        id: 1,
        title: 'गर्मी का दिन',
        background: SceneBackground.hotDay,
        narration:
            'एक दिन बहुत तेज़ गर्मी थी। एक छोटा कौआ पानी की तलाश में आसमान '
            'में उड़ रहा था।',
        camera: CameraEffect.zoomIn,
        props: <SceneProp>[
          SceneProp(id: 'sun', kind: PropKind.sun, x: 0.78, y: 0.16, scale: 1.2),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.35,
            y: 0.45,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.sunRays, ParticleKind.wind],
        interaction: SceneInteraction(
          type: InteractionType.tap,
          target: 'sun',
          hint: 'सूरज को छुओ!',
          sound: 'chime',
        ),
      ),
      StoryScene(
        id: 2,
        title: 'पानी की तलाश',
        background: SceneBackground.village,
        narration:
            'कौआ बहुत प्यासा था। उसने यहाँ देखा, वहाँ देखा, पर कहीं पानी नहीं '
            'मिला।',
        camera: CameraEffect.panRight,
        props: <SceneProp>[
          SceneProp(id: 'house', kind: PropKind.house, x: 0.2, y: 0.68),
          SceneProp(id: 'tree', kind: PropKind.tree, x: 0.82, y: 0.6, scale: 1.1),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.42,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.wind],
      ),
      StoryScene(
        id: 3,
        title: 'घड़ा मिला',
        background: SceneBackground.village,
        narration:
            'तभी उसे पेड़ के नीचे एक घड़ा दिखा! क्या तुम कौए को घड़े तक '
            'पहुँचा सकते हो?',
        camera: CameraEffect.zoomIn,
        props: <SceneProp>[
          SceneProp(id: 'tree', kind: PropKind.tree, x: 0.75, y: 0.55, scale: 1.2),
          SceneProp(id: 'pot', kind: PropKind.pot, x: 0.6, y: 0.78),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(id: 'crow', kind: CharacterKind.crow, x: 0.2, y: 0.4),
        ],
        particles: <ParticleKind>[ParticleKind.birds],
        interaction: SceneInteraction(
          type: InteractionType.drag,
          target: 'crow',
          dropZone: 'pot',
          hint: 'कौए को घड़े तक ले जाओ!',
          sound: 'plop',
        ),
      ),
      StoryScene(
        id: 4,
        title: 'चतुर कौआ',
        minDuration: 9,
        background: SceneBackground.village,
        narration:
            'पानी बहुत नीचे था। चतुर कौए ने एक-एक करके छोटे कंकड़ घड़े में '
            'डाले, और पानी ऊपर आता गया!',
        props: <SceneProp>[
          SceneProp(id: 'pot', kind: PropKind.pot, x: 0.5, y: 0.72, scale: 1.3),
          SceneProp(id: 'rock', kind: PropKind.rock, x: 0.25, y: 0.82, scale: 0.8),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.45,
            animation: CharacterAnimation.bounce,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.bubbles],
      ),
      StoryScene(
        id: 5,
        title: 'खुशी की उड़ान',
        background: SceneBackground.sky,
        narration:
            'कौए ने ठंडा पानी पिया और खुशी-खुशी उड़ गया। जब कोई काम मुश्किल '
            'लगे, तो सोचो और कोशिश करो — जहाँ चाह, वहाँ राह!',
        camera: CameraEffect.zoomOut,
        props: <SceneProp>[
          SceneProp(id: 'sun', kind: PropKind.sun, x: 0.8, y: 0.15),
          SceneProp(id: 'cloud', kind: PropKind.cloud, x: 0.25, y: 0.2),
        ],
        characters: <SceneCharacter>[
          SceneCharacter(
            id: 'crow',
            kind: CharacterKind.crow,
            x: 0.5,
            y: 0.4,
            scale: 1.1,
            animation: CharacterAnimation.fly,
          ),
        ],
        particles: <ParticleKind>[ParticleKind.birds, ParticleKind.wind],
      ),
    ],
  );
}
