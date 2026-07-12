import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Cinematic story models — the scene-script format the story player renders.
//
// The backend's LLM writes the SCRIPT only; every visual is a closed enum this
// app knows how to draw (background presets, prop/character kinds, particles),
// so stories need zero downloaded assets and play offline. The enum wire
// values mirror kids-app-backend/src/services/cinematic.schema.ts — keep both
// sides in sync. Parsing is lenient: an unknown wire value degrades to a safe
// default instead of crashing an older app on newer vocabulary.
// ---------------------------------------------------------------------------

enum SceneBackground {
  hotDay('hot_day'),
  forest('forest'),
  night('night'),
  pond('pond'),
  village('village'),
  sky('sky'),
  rain('rain');

  const SceneBackground(this.wire);
  final String wire;

  static SceneBackground parse(String? v) => values.firstWhere(
        (SceneBackground b) => b.wire == v,
        orElse: () => SceneBackground.sky,
      );
}

enum PropKind {
  sun('sun'),
  cloud('cloud'),
  tree('tree'),
  pot('pot'),
  pond('pond'),
  house('house'),
  rock('rock'),
  bush('bush'),
  mountain('mountain'),
  flower('flower'),
  star('star'),
  moon('moon');

  const PropKind(this.wire);
  final String wire;

  static PropKind parse(String? v) => values.firstWhere(
        (PropKind k) => k.wire == v,
        orElse: () => PropKind.cloud,
      );
}

enum CharacterKind {
  crow('crow', '🐦‍⬛'),
  rabbit('rabbit', '🐰'),
  turtle('turtle', '🐢'),
  lion('lion', '🦁'),
  mouse('mouse', '🐭'),
  elephant('elephant', '🐘'),
  monkey('monkey', '🐵'),
  dog('dog', '🐶'),
  cat('cat', '🐱'),
  bird('bird', '🐦');

  const CharacterKind(this.wire, this.emoji);
  final String wire;

  /// Original emoji rendering — same approach as the buddy catalog, no
  /// licensed IP and no downloaded sprites.
  final String emoji;

  static CharacterKind parse(String? v) => values.firstWhere(
        (CharacterKind k) => k.wire == v,
        orElse: () => CharacterKind.bird,
      );
}

enum ParticleKind {
  sunRays('sun_rays'),
  wind('wind'),
  birds('birds'),
  leaves('leaves'),
  rain('rain'),
  stars('stars'),
  bubbles('bubbles');

  const ParticleKind(this.wire);
  final String wire;

  static ParticleKind? parse(String? v) {
    for (final ParticleKind k in values) {
      if (k.wire == v) return k;
    }
    return null; // Unknown particle → simply not rendered.
  }
}

enum CharacterAnimation {
  idle('idle'),
  fly('fly'),
  hop('hop'),
  walk('walk'),
  bounce('bounce');

  const CharacterAnimation(this.wire);
  final String wire;

  static CharacterAnimation parse(String? v) => values.firstWhere(
        (CharacterAnimation a) => a.wire == v,
        orElse: () => CharacterAnimation.idle,
      );
}

enum CameraEffect {
  none('none'),
  zoomIn('zoom_in'),
  zoomOut('zoom_out'),
  panLeft('pan_left'),
  panRight('pan_right');

  const CameraEffect(this.wire);
  final String wire;

  static CameraEffect parse(String? v) => values.firstWhere(
        (CameraEffect e) => e.wire == v,
        orElse: () => CameraEffect.none,
      );
}

enum MusicTrack {
  forest('forest'),
  calm('calm'),
  playful('playful'),
  night('night');

  const MusicTrack(this.wire);
  final String wire;

  static MusicTrack parse(String? v) => values.firstWhere(
        (MusicTrack t) => t.wire == v,
        orElse: () => MusicTrack.calm,
      );
}

enum InteractionType {
  tap('tap'),
  drag('drag');

  const InteractionType(this.wire);
  final String wire;

  static InteractionType parse(String? v) => values.firstWhere(
        (InteractionType t) => t.wire == v,
        orElse: () => InteractionType.tap,
      );
}

@immutable
class SceneProp {
  const SceneProp({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.scale = 1,
  });

  final String id;
  final PropKind kind;

  /// Relative position (0..1 of the stage; y grows downward).
  final double x;
  final double y;
  final double scale;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.wire,
        'x': x,
        'y': y,
        'scale': scale,
      };

  factory SceneProp.fromJson(Map<String, dynamic> j) => SceneProp(
        id: j['id'] as String? ?? '',
        kind: PropKind.parse(j['kind'] as String?),
        x: (j['x'] as num?)?.toDouble() ?? 0.5,
        y: (j['y'] as num?)?.toDouble() ?? 0.5,
        scale: (j['scale'] as num?)?.toDouble() ?? 1,
      );
}

@immutable
class SceneCharacter {
  const SceneCharacter({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.scale = 1,
    this.animation = CharacterAnimation.idle,
  });

  final String id;
  final CharacterKind kind;
  final double x;
  final double y;
  final double scale;
  final CharacterAnimation animation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.wire,
        'x': x,
        'y': y,
        'scale': scale,
        'animation': animation.wire,
      };

  factory SceneCharacter.fromJson(Map<String, dynamic> j) => SceneCharacter(
        id: j['id'] as String? ?? '',
        kind: CharacterKind.parse(j['kind'] as String?),
        x: (j['x'] as num?)?.toDouble() ?? 0.5,
        y: (j['y'] as num?)?.toDouble() ?? 0.5,
        scale: (j['scale'] as num?)?.toDouble() ?? 1,
        animation: CharacterAnimation.parse(j['animation'] as String?),
      );
}

@immutable
class SceneInteraction {
  const SceneInteraction({
    required this.type,
    required this.target,
    required this.hint,
    this.dropZone,
    this.sound = 'chime',
  });

  final InteractionType type;

  /// Id of the prop/character the child taps or drags.
  final String target;

  /// Drag only: id of the prop/character the target is dropped onto.
  final String? dropZone;

  /// Spoken + shown instruction, already in the story's language.
  final String hint;

  /// Bundled SFX name played on success (matches the Sfx enum names).
  final String sound;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.wire,
        'target': target,
        'dropZone': dropZone,
        'hint': hint,
        'sound': sound,
      };

  factory SceneInteraction.fromJson(Map<String, dynamic> j) => SceneInteraction(
        type: InteractionType.parse(j['type'] as String?),
        target: j['target'] as String? ?? '',
        dropZone: j['dropZone'] as String?,
        hint: j['hint'] as String? ?? '',
        sound: j['sound'] as String? ?? 'chime',
      );
}

@immutable
class StoryScene {
  const StoryScene({
    required this.id,
    required this.title,
    required this.background,
    required this.narration,
    this.minDuration = 8,
    this.camera = CameraEffect.none,
    this.props = const <SceneProp>[],
    this.characters = const <SceneCharacter>[],
    this.particles = const <ParticleKind>[],
    this.interaction,
  });

  final int id;
  final String title;

  /// Minimum seconds on screen (narration may hold the scene longer).
  final double minDuration;
  final SceneBackground background;

  /// 1-2 sentences, spoken via TTS and shown as the subtitle.
  final String narration;
  final CameraEffect camera;
  final List<SceneProp> props;
  final List<SceneCharacter> characters;
  final List<ParticleKind> particles;
  final SceneInteraction? interaction;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'minDuration': minDuration,
        'background': background.wire,
        'narration': narration,
        'camera': <String, dynamic>{'effect': camera.wire},
        'props': props.map((SceneProp p) => p.toJson()).toList(),
        'characters': characters.map((SceneCharacter c) => c.toJson()).toList(),
        'particles': particles.map((ParticleKind p) => p.wire).toList(),
        'interaction': interaction?.toJson(),
      };

  factory StoryScene.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic>? camera = j['camera'] as Map<String, dynamic>?;
    final Map<String, dynamic>? interaction =
        j['interaction'] as Map<String, dynamic>?;
    return StoryScene(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title'] as String? ?? '',
      minDuration: (j['minDuration'] as num?)?.toDouble() ?? 8,
      background: SceneBackground.parse(j['background'] as String?),
      narration: j['narration'] as String? ?? '',
      camera: CameraEffect.parse(camera?['effect'] as String?),
      props: ((j['props'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic p) => SceneProp.fromJson(p as Map<String, dynamic>))
          .toList(),
      characters: ((j['characters'] as List<dynamic>?) ?? <dynamic>[])
          .map(
            (dynamic c) => SceneCharacter.fromJson(c as Map<String, dynamic>),
          )
          .toList(),
      particles: ((j['particles'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic p) => ParticleKind.parse(p as String?))
          .whereType<ParticleKind>()
          .toList(),
      interaction: interaction == null
          ? null
          : SceneInteraction.fromJson(interaction),
    );
  }
}

@immutable
class StoryReward {
  const StoryReward({
    this.stars = 10,
    this.coins = 5,
    this.badgeStickerId = 'star',
  });

  final int stars;
  final int coins;
  final String badgeStickerId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stars': stars,
        'coins': coins,
        'badgeStickerId': badgeStickerId,
      };

  factory StoryReward.fromJson(Map<String, dynamic>? j) => StoryReward(
        stars: (j?['stars'] as num?)?.toInt() ?? 10,
        coins: (j?['coins'] as num?)?.toInt() ?? 5,
        badgeStickerId: j?['badgeStickerId'] as String? ?? 'star',
      );
}

@immutable
class CinematicStory {
  const CinematicStory({
    required this.id,
    required this.slug,
    required this.title,
    required this.lang,
    required this.ageBand,
    required this.coverEmoji,
    required this.moral,
    required this.scenes,
    this.category = 'Moral Stories',
    this.music = MusicTrack.calm,
    this.reward = const StoryReward(),
  });

  final String id;
  final String slug;
  final String title;

  /// "en" | "hi" — the language every text field is written in.
  final String lang;
  final String ageBand;
  final String category;
  final String coverEmoji;
  final MusicTrack music;
  final String moral;
  final StoryReward reward;
  final List<StoryScene> scenes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'slug': slug,
        'title': title,
        'lang': lang,
        'ageBand': ageBand,
        'category': category,
        'coverEmoji': coverEmoji,
        'music': music.wire,
        'moral': moral,
        'reward': reward.toJson(),
        'scenes': scenes.map((StoryScene s) => s.toJson()).toList(),
      };

  factory CinematicStory.fromJson(Map<String, dynamic> j) => CinematicStory(
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        title: j['title'] as String? ?? '',
        lang: j['lang'] as String? ?? 'en',
        ageBand: j['ageBand'] as String? ?? 'junior',
        category: j['category'] as String? ?? 'Moral Stories',
        coverEmoji: j['coverEmoji'] as String? ?? '📖',
        music: MusicTrack.parse(j['music'] as String?),
        moral: j['moral'] as String? ?? '',
        reward: StoryReward.fromJson(j['reward'] as Map<String, dynamic>?),
        scenes: ((j['scenes'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic s) => StoryScene.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
