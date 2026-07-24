import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'cinematic_story.dart';

// ---------------------------------------------------------------------------
// Cinematic story models — v2 "director track".
//
// The big shift from v1 (`cinematic_story.dart`): a scene is no longer a slide
// (one image + one narration + one BLOCKING interaction). It is a TIMELINE — an
// ordered list of timestamped [SceneCue]s (dialogue, camera moves, character
// actions, sfx, music swells, ambient beats, optional non-blocking hotspots)
// that advance on a clock. The story plays itself; taps are garnish that never
// gate progress.
//
// Design invariants (kept from v1):
//  * Offline-first vector baseline: every visual/audio token is a closed enum
//    the app knows how to draw/play, so a story needs zero downloaded assets.
//    Illustration / Rive / audio URLs are always OPTIONAL enrichment.
//  * Lenient parsing: an unknown wire value degrades to a safe default (or, for
//    cues, is skipped) instead of crashing an older app on newer vocabulary.
//
// The reused enums (`SceneBackground`, `PropKind`, `CharacterKind`,
// `ParticleKind`, `MusicTrack`) + `SceneProp`/`StoryReward` come from
// `cinematic_story.dart` so the two schema versions never drift.
//
// Wire values mirror kids-app-backend/src/services/cinematic.schema.ts (v2).
// See backend_samples/cinematic_story_v2_hare_and_tortoise.json for a full
// sample and backend_samples/README_v2_schema.md for the field reference.
// ---------------------------------------------------------------------------

// ── Environment + mood enums ───────────────────────────────────────────────

enum SceneMood {
  cheerful('cheerful'),
  calm('calm'),
  tense('tense'),
  triumphant('triumphant'),
  tender('tender'),
  sleepy('sleepy'),
  mysterious('mysterious');

  const SceneMood(this.wire);
  final String wire;

  static SceneMood parse(String? v) => values.firstWhere(
        (SceneMood m) => m.wire == v,
        orElse: () => SceneMood.calm,
      );
}

enum SceneTimeOfDay {
  dawn('dawn'),
  morning('morning'),
  noon('noon'),
  afternoon('afternoon'),
  dusk('dusk'),
  night('night');

  const SceneTimeOfDay(this.wire);
  final String wire;

  static SceneTimeOfDay parse(String? v) => values.firstWhere(
        (SceneTimeOfDay t) => t.wire == v,
        orElse: () => SceneTimeOfDay.morning,
      );
}

enum SceneWeather {
  clear('clear'),
  cloudy('cloudy'),
  rain('rain'),
  snow('snow'),
  windy('windy'),
  fog('fog');

  const SceneWeather(this.wire);
  final String wire;

  static SceneWeather parse(String? v) => values.firstWhere(
        (SceneWeather w) => w.wire == v,
        orElse: () => SceneWeather.clear,
      );
}

enum SceneLighting {
  warm('warm'),
  cool('cool'),
  golden('golden'),
  moonlit('moonlit'),
  overcast('overcast');

  const SceneLighting(this.wire);
  final String wire;

  static SceneLighting parse(String? v) => values.firstWhere(
        (SceneLighting l) => l.wire == v,
        orElse: () => SceneLighting.warm,
      );
}

enum StageRenderer {
  /// Try the richest available layer (image → rive → vector) and fall back.
  auto('auto'),
  vector('vector'),
  image('image'),
  rive('rive'),
  lottie('lottie'),
  spine('spine'),
  sprite('sprite');

  const StageRenderer(this.wire);
  final String wire;

  static StageRenderer parse(String? v) => values.firstWhere(
        (StageRenderer r) => r.wire == v,
        orElse: () => StageRenderer.vector,
      );
}

/// A character's on-stage feeling — drives idle pose, and is named in
/// narration/dialogue for early SEL ("the hare felt proud").
enum Emotion {
  neutral('neutral'),
  happy('happy'),
  proud('proud'),
  worried('worried'),
  sad('sad'),
  scared('scared'),
  kind('kind'),
  sleepy('sleepy'),
  surprised('surprised'),
  determined('determined');

  const Emotion(this.wire);
  final String wire;

  static Emotion parse(String? v) => values.firstWhere(
        (Emotion e) => e.wire == v,
        orElse: () => Emotion.neutral,
      );
}

/// A scripted character action fired by a [CharacterCue]. A superset of v1's
/// `CharacterAnimation` (idle/fly/hop/walk/bounce) with acting beats.
enum CharacterAction {
  idle('idle'),
  fly('fly'),
  hop('hop'),
  walk('walk'),
  run('run'),
  bounce('bounce'),
  jump('jump'),
  laugh('laugh'),
  cry('cry'),
  sleep('sleep'),
  nod('nod'),
  shake('shake'),
  fall('fall'),
  celebrate('celebrate');

  const CharacterAction(this.wire);
  final String wire;

  static CharacterAction parse(String? v) => values.firstWhere(
        (CharacterAction a) => a.wire == v,
        orElse: () => CharacterAction.idle,
      );
}

enum SceneTransitionType {
  cut('cut'),
  fade('fade'),
  dissolve('dissolve'),
  slide('slide'),
  irisIn('iris_in'),
  irisOut('iris_out'),
  whipPan('whip_pan'),
  pageTurn('page_turn');

  const SceneTransitionType(this.wire);
  final String wire;

  static SceneTransitionType parse(String? v) => values.firstWhere(
        (SceneTransitionType t) => t.wire == v,
        orElse: () => SceneTransitionType.fade,
      );
}

enum CameraEase {
  linear('linear'),
  easeIn('easeIn'),
  easeOut('easeOut'),
  easeInOut('easeInOut'),
  easeInOutSine('easeInOutSine'),
  easeOutBack('easeOutBack');

  const CameraEase(this.wire);
  final String wire;

  static CameraEase parse(String? v) => values.firstWhere(
        (CameraEase e) => e.wire == v,
        orElse: () => CameraEase.easeInOut,
      );
}

enum HotspotTrigger {
  tap('tap'),
  drag('drag');

  const HotspotTrigger(this.wire);
  final String wire;

  static HotspotTrigger parse(String? v) => values.firstWhere(
        (HotspotTrigger t) => t.wire == v,
        orElse: () => HotspotTrigger.tap,
      );
}

// ── Camera (keyframed rig, not an enum) ────────────────────────────────────

@immutable
class CameraKeyframe {
  const CameraKeyframe({
    this.targetId,
    this.zoom = 1,
    this.offset = Offset.zero,
  });

  /// Optional cast/prop id to centre on ("push in on the tortoise").
  final String? targetId;

  /// 1 = no zoom; >1 pushes in.
  final double zoom;

  /// Ken Burns drift, in fractions of the stage size.
  final Offset offset;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (targetId != null) 'target': targetId,
        'zoom': zoom,
        'offset': <double>[offset.dx, offset.dy],
      };

  factory CameraKeyframe.fromJson(Map<String, dynamic> j) {
    final List<dynamic>? off = j['offset'] as List<dynamic>?;
    return CameraKeyframe(
      targetId: j['target'] as String?,
      zoom: (j['zoom'] as num?)?.toDouble() ?? 1,
      offset: off == null || off.length < 2
          ? Offset.zero
          : Offset(
              (off[0] as num).toDouble(),
              (off[1] as num).toDouble(),
            ),
    );
  }
}

@immutable
class SceneCamera {
  const SceneCamera({
    this.from = const CameraKeyframe(),
    this.to = const CameraKeyframe(),
    this.duration = 6,
    this.ease = CameraEase.easeInOut,
    this.startAt = 0,
  });

  final CameraKeyframe from;
  final CameraKeyframe to;

  /// Seconds the move takes.
  final double duration;
  final CameraEase ease;

  /// Seconds into the scene at which the move begins.
  final double startAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'from': from.toJson(),
        'to': to.toJson(),
        'duration': duration,
        'ease': ease.wire,
        'startAt': startAt,
      };

  factory SceneCamera.fromJson(Map<String, dynamic> j) => SceneCamera(
        from: j['from'] is Map<String, dynamic>
            ? CameraKeyframe.fromJson(j['from'] as Map<String, dynamic>)
            : const CameraKeyframe(),
        to: j['to'] is Map<String, dynamic>
            ? CameraKeyframe.fromJson(j['to'] as Map<String, dynamic>)
            : const CameraKeyframe(),
        duration: (j['duration'] as num?)?.toDouble() ?? 6,
        ease: CameraEase.parse(j['ease'] as String?),
        startAt: (j['startAt'] as num?)?.toDouble() ?? 0,
      );
}

// ── Cast (who is on stage; emotion is first-class) ─────────────────────────

@immutable
class CharacterEntrance {
  const CharacterEntrance({required this.from, required this.at});

  /// 'left' | 'right' | 'top' | 'bottom' — the edge the character slides in
  /// from. Unknown values are treated as no slide (already on stage).
  final String from;

  /// Seconds into the scene the entrance begins.
  final double at;

  Map<String, dynamic> toJson() => <String, dynamic>{'from': from, 'at': at};

  factory CharacterEntrance.fromJson(Map<String, dynamic> j) =>
      CharacterEntrance(
        from: j['from'] as String? ?? 'left',
        at: (j['at'] as num?)?.toDouble() ?? 0,
      );
}

@immutable
class CastMember {
  const CastMember({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    this.scale = 1,
    this.facing = 'right',
    this.emotion = Emotion.neutral,
    this.asset,
    this.entrance,
  });

  final String id;
  final CharacterKind kind;

  /// Relative position (0..1 of the stage; y grows downward).
  final double x;
  final double y;
  final double scale;

  /// 'left' | 'right' — which way the character faces (mirror the sprite).
  final String facing;
  final Emotion emotion;

  /// Optional asset-manifest id (a Rive/sprite). Null → emoji/vector render.
  final String? asset;
  final CharacterEntrance? entrance;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.wire,
        'x': x,
        'y': y,
        'scale': scale,
        'facing': facing,
        'emotion': emotion.wire,
        if (asset != null) 'asset': asset,
        if (entrance != null) 'entrance': entrance!.toJson(),
      };

  factory CastMember.fromJson(Map<String, dynamic> j) => CastMember(
        id: j['id'] as String? ?? '',
        kind: CharacterKind.parse(j['kind'] as String?),
        x: (j['x'] as num?)?.toDouble() ?? 0.5,
        y: (j['y'] as num?)?.toDouble() ?? 0.6,
        scale: (j['scale'] as num?)?.toDouble() ?? 1,
        facing: j['facing'] as String? ?? 'right',
        emotion: Emotion.parse(j['emotion'] as String?),
        asset: j['asset'] as String?,
        entrance: j['entrance'] is Map<String, dynamic>
            ? CharacterEntrance.fromJson(j['entrance'] as Map<String, dynamic>)
            : null,
      );
}

// ── Stage (layered renderers + parallax) ───────────────────────────────────

@immutable
class StageLayer {
  const StageLayer({required this.z, this.props = const <SceneProp>[]});

  /// Depth order (lower = further back). Used for parallax.
  final int z;
  final List<SceneProp> props;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'z': z,
        'props': props.map((SceneProp p) => p.toJson()).toList(),
      };

  factory StageLayer.fromJson(Map<String, dynamic> j) => StageLayer(
        z: (j['z'] as num?)?.toInt() ?? 0,
        props: ((j['props'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic p) => SceneProp.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class SceneStage {
  const SceneStage({
    this.renderer = StageRenderer.auto,
    this.image,
    this.layers = const <StageLayer>[],
  });

  final StageRenderer renderer;

  /// Optional full-bleed illustration (asset-manifest id or URL).
  final String? image;
  final List<StageLayer> layers;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'renderer': renderer.wire,
        if (image != null) 'image': image,
        'layers': layers.map((StageLayer l) => l.toJson()).toList(),
      };

  factory SceneStage.fromJson(Map<String, dynamic> j) => SceneStage(
        renderer: StageRenderer.parse(j['renderer'] as String?),
        image: j['image'] as String?,
        layers: ((j['layers'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic l) => StageLayer.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

// ── Narration (with optional word timing → read-along) ─────────────────────

@immutable
class NarrationMark {
  const NarrationMark({required this.word, required this.t});

  final String word;

  /// Seconds into the scene the word is spoken (drives karaoke highlight).
  final double t;

  Map<String, dynamic> toJson() => <String, dynamic>{'w': word, 't': t};

  factory NarrationMark.fromJson(Map<String, dynamic> j) => NarrationMark(
        word: j['w'] as String? ?? '',
        t: (j['t'] as num?)?.toDouble() ?? 0,
      );
}

@immutable
class Narration {
  const Narration({
    required this.text,
    this.marks = const <NarrationMark>[],
    this.granularity = 'sentence',
  });

  /// The full narration line, in the story's language. Spoken via VO/TTS and
  /// shown as the subtitle.
  final String text;

  /// Optional per-word timing. Empty → highlight falls back to none/sentence.
  final List<NarrationMark> marks;

  /// 'word' | 'sentence' — highlight granularity (word for slow junior VO).
  final String granularity;

  bool get hasWordTiming => marks.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        if (marks.isNotEmpty)
          'marks': marks.map((NarrationMark m) => m.toJson()).toList(),
        'granularity': granularity,
      };

  factory Narration.fromJson(Object? j) {
    // Lenient: accept either a bare string or the rich object.
    if (j is String) return Narration(text: j);
    if (j is Map<String, dynamic>) {
      return Narration(
        text: j['text'] as String? ?? '',
        marks: ((j['marks'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic m) =>
                NarrationMark.fromJson(m as Map<String, dynamic>),)
            .toList(),
        granularity: j['granularity'] as String? ?? 'sentence',
      );
    }
    return const Narration(text: '');
  }
}

// ── Audio (story + per-scene beds) ─────────────────────────────────────────

@immutable
class MusicBed {
  const MusicBed(
      {this.track = MusicTrack.calm, this.volume = 0.6, this.loop = true,});

  final MusicTrack track;
  final double volume;
  final bool loop;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'track': track.wire,
        'volume': volume,
        'loop': loop,
      };

  factory MusicBed.fromJson(Map<String, dynamic> j) => MusicBed(
        track: MusicTrack.parse(j['track'] as String?),
        volume: (j['volume'] as num?)?.toDouble() ?? 0.6,
        loop: j['loop'] as bool? ?? true,
      );
}

@immutable
class AmbienceBed {
  const AmbienceBed({this.bed = 'none', this.volume = 0.4, this.loop = true});

  /// Named ambience loop ('meadow', 'pond', 'rain', 'birds_meadow'…). Unknown
  /// names simply play nothing.
  final String bed;
  final double volume;
  final bool loop;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bed': bed,
        'volume': volume,
        'loop': loop,
      };

  factory AmbienceBed.fromJson(Map<String, dynamic> j) => AmbienceBed(
        bed: j['bed'] as String? ?? 'none',
        volume: (j['volume'] as num?)?.toDouble() ?? 0.4,
        loop: j['loop'] as bool? ?? true,
      );
}

@immutable
class SceneAudio {
  const SceneAudio({this.music, this.ambience});

  final MusicBed? music;
  final AmbienceBed? ambience;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (music != null) 'music': music!.toJson(),
        if (ambience != null) 'ambience': ambience!.toJson(),
      };

  factory SceneAudio.fromJson(Map<String, dynamic> j) => SceneAudio(
        music: j['music'] is Map<String, dynamic>
            ? MusicBed.fromJson(j['music'] as Map<String, dynamic>)
            : null,
        ambience: j['ambience'] is Map<String, dynamic>
            ? AmbienceBed.fromJson(j['ambience'] as Map<String, dynamic>)
            : null,
      );
}

@immutable
class StoryAudio {
  const StoryAudio({
    this.music = const MusicBed(),
    this.ambience = const AmbienceBed(),
    this.voicePack,
    this.narrationSpeed = 1,
  });

  final MusicBed music;
  final AmbienceBed ambience;

  /// Narrator identity id ('warm_female_en'…). Null → on-device TTS default.
  final String? voicePack;
  final double narrationSpeed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'music': music.toJson(),
        'ambience': ambience.toJson(),
        if (voicePack != null) 'voicePack': voicePack,
        'narrationSpeed': narrationSpeed,
      };

  factory StoryAudio.fromJson(Map<String, dynamic>? j) => StoryAudio(
        music: j?['music'] is Map<String, dynamic>
            ? MusicBed.fromJson(j!['music'] as Map<String, dynamic>)
            : const MusicBed(),
        ambience: j?['ambience'] is Map<String, dynamic>
            ? AmbienceBed.fromJson(j!['ambience'] as Map<String, dynamic>)
            : const AmbienceBed(),
        voicePack: j?['voicePack'] as String?,
        narrationSpeed: (j?['narrationSpeed'] as num?)?.toDouble() ?? 1,
      );
}

// ── Transitions ────────────────────────────────────────────────────────────

@immutable
class TransitionSpec {
  const TransitionSpec({
    this.type = SceneTransitionType.fade,
    this.duration = 0.6,
  });

  final SceneTransitionType type;
  final double duration;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.wire,
        'duration': duration,
      };

  factory TransitionSpec.fromJson(Map<String, dynamic>? j) => TransitionSpec(
        type: SceneTransitionType.parse(j?['type'] as String?),
        duration: (j?['duration'] as num?)?.toDouble() ?? 0.6,
      );
}

@immutable
class SceneTransition {
  const SceneTransition({
    this.enter = const TransitionSpec(),
    this.exit = const TransitionSpec(type: SceneTransitionType.dissolve),
  });

  final TransitionSpec enter;
  final TransitionSpec exit;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'in': enter.toJson(),
        'out': exit.toJson(),
      };

  factory SceneTransition.fromJson(Map<String, dynamic>? j) => SceneTransition(
        enter: TransitionSpec.fromJson(j?['in'] as Map<String, dynamic>?),
        exit: TransitionSpec.fromJson(j?['out'] as Map<String, dynamic>?),
      );
}

// ── Cues (THE TIMELINE — ordered, timestamped beats) ───────────────────────

/// Base of the cue discriminated union. Every cue carries [t], its start time
/// in seconds from scene begin. Parse returns null for unknown types so an
/// older app silently skips vocabulary it doesn't understand.
@immutable
sealed class SceneCue {
  const SceneCue({required this.t});

  final double t;

  /// How long the cue occupies the timeline (for scene-duration math). Most
  /// cues are instantaneous; [HoldCue] overrides this.
  double get span => 0;

  Map<String, dynamic> toJson();

  static double _t(Map<String, dynamic> j) => (j['t'] as num?)?.toDouble() ?? 0;

  static SceneCue? parse(Map<String, dynamic> j) {
    switch (j['type'] as String?) {
      case 'dialogue':
        return DialogueCue.fromJson(j);
      case 'character':
        return CharacterCue.fromJson(j);
      case 'prop':
        return PropCue.fromJson(j);
      case 'camera':
        return CameraCue.fromJson(j);
      case 'sfx':
        return SfxCue.fromJson(j);
      case 'music':
        return MusicCue.fromJson(j);
      case 'ambient':
        return AmbientCue.fromJson(j);
      case 'hold':
        return HoldCue.fromJson(j);
      case 'caption':
        return CaptionCue.fromJson(j);
      case 'interaction':
        return InteractionCue.fromJson(j);
      default:
        return null; // Unknown cue type → skipped.
    }
  }
}

@immutable
class DialogueCue extends SceneCue {
  const DialogueCue({
    required super.t,
    required this.speaker,
    required this.text,
    this.emotion = Emotion.neutral,
    this.duckMusicDb = -6,
  });

  /// Cast id of the speaker.
  final String speaker;
  final String text;
  final Emotion emotion;

  /// How far to duck the music bed under this line (negative dB).
  final double duckMusicDb;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'dialogue',
        't': t,
        'speaker': speaker,
        'text': text,
        'emotion': emotion.wire,
        'duckMusicDb': duckMusicDb,
      };

  factory DialogueCue.fromJson(Map<String, dynamic> j) => DialogueCue(
        t: SceneCue._t(j),
        speaker: j['speaker'] as String? ?? '',
        text: j['text'] as String? ?? '',
        emotion: Emotion.parse(j['emotion'] as String?),
        duckMusicDb: (j['duckMusicDb'] as num?)?.toDouble() ?? -6,
      );
}

@immutable
class CharacterCue extends SceneCue {
  const CharacterCue({
    required super.t,
    required this.target,
    required this.action,
  });

  final String target;
  final CharacterAction action;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'character',
        't': t,
        'target': target,
        'action': action.wire,
      };

  factory CharacterCue.fromJson(Map<String, dynamic> j) => CharacterCue(
        t: SceneCue._t(j),
        target: j['target'] as String? ?? '',
        action: CharacterAction.parse(j['action'] as String?),
      );
}

@immutable
class PropCue extends SceneCue {
  const PropCue({
    required super.t,
    required this.target,
    this.action = 'animate',
  });

  final String target;

  /// 'appear' | 'hide' | 'animate' — free-form; renderer interprets.
  final String action;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'prop',
        't': t,
        'target': target,
        'action': action,
      };

  factory PropCue.fromJson(Map<String, dynamic> j) => PropCue(
        t: SceneCue._t(j),
        target: j['target'] as String? ?? '',
        action: j['action'] as String? ?? 'animate',
      );
}

@immutable
class CameraCue extends SceneCue {
  const CameraCue({required super.t, required this.move});

  /// A mid-scene camera move; [SceneCamera.startAt] defaults to this cue's [t].
  final SceneCamera move;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'camera',
        't': t,
        'move': move.toJson(),
      };

  factory CameraCue.fromJson(Map<String, dynamic> j) {
    final double t = SceneCue._t(j);
    final Map<String, dynamic> move = (j['move'] as Map<String, dynamic>?) ?? j;
    final SceneCamera parsed = SceneCamera.fromJson(move);
    return CameraCue(
      t: t,
      // Default the move's startAt to the cue time when unspecified.
      move: move.containsKey('startAt')
          ? parsed
          : SceneCamera(
              from: parsed.from,
              to: parsed.to,
              duration: parsed.duration,
              ease: parsed.ease,
              startAt: t,
            ),
    );
  }
}

@immutable
class SfxCue extends SceneCue {
  const SfxCue({required super.t, required this.sound, this.volume = 1});

  /// SFX name (matches the app's Sfx enum). Unknown names fall back to a chime.
  final String sound;
  final double volume;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'sfx',
        't': t,
        'sound': sound,
        'volume': volume,
      };

  factory SfxCue.fromJson(Map<String, dynamic> j) => SfxCue(
        t: SceneCue._t(j),
        sound: j['sound'] as String? ?? 'chime',
        volume: (j['volume'] as num?)?.toDouble() ?? 1,
      );
}

@immutable
class MusicCue extends SceneCue {
  const MusicCue({required super.t, required this.track, this.volume = 0.6});

  /// Crossfade the music bed to this track (adaptive music per emotional beat).
  final MusicTrack track;
  final double volume;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'music',
        't': t,
        'track': track.wire,
        'volume': volume,
      };

  factory MusicCue.fromJson(Map<String, dynamic> j) => MusicCue(
        t: SceneCue._t(j),
        track: MusicTrack.parse(j['track'] as String?),
        volume: (j['volume'] as num?)?.toDouble() ?? 0.6,
      );
}

@immutable
class AmbientCue extends SceneCue {
  const AmbientCue({required super.t, required this.bed, this.volume = 0.4});

  final String bed;
  final double volume;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'ambient',
        't': t,
        'bed': bed,
        'volume': volume,
      };

  factory AmbientCue.fromJson(Map<String, dynamic> j) => AmbientCue(
        t: SceneCue._t(j),
        bed: j['bed'] as String? ?? 'none',
        volume: (j['volume'] as num?)?.toDouble() ?? 0.4,
      );
}

@immutable
class HoldCue extends SceneCue {
  const HoldCue({required super.t, this.duration = 1});

  /// A deliberate silent beat (the dramatic pause).
  final double duration;

  @override
  double get span => duration;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'hold',
        't': t,
        'duration': duration,
      };

  factory HoldCue.fromJson(Map<String, dynamic> j) => HoldCue(
        t: SceneCue._t(j),
        duration: (j['duration'] as num?)?.toDouble() ?? 1,
      );
}

@immutable
class CaptionCue extends SceneCue {
  const CaptionCue({required super.t, required this.text, this.duration = 2});

  final String text;
  final double duration;

  @override
  double get span => duration;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'caption',
        't': t,
        'text': text,
        'duration': duration,
      };

  factory CaptionCue.fromJson(Map<String, dynamic> j) => CaptionCue(
        t: SceneCue._t(j),
        text: j['text'] as String? ?? '',
        duration: (j['duration'] as num?)?.toDouble() ?? 2,
      );
}

/// An OPTIONAL, non-blocking hotspot. It lives for the whole scene (its [t] is
/// when it becomes tappable, usually 0) and NEVER appears in the scene-advance
/// condition — ignore it and the story flows on untouched.
@immutable
class InteractionCue extends SceneCue {
  const InteractionCue({
    required super.t,
    required this.target,
    this.trigger = HotspotTrigger.tap,
    this.reaction = 'sparkle',
    this.sound = 'twinkle',
    this.optional = true,
    this.narrateOnMiss = false,
  });

  /// Cast/prop id (or 'stage' for the whole canvas) that reacts.
  final String target;
  final HotspotTrigger trigger;

  /// Reaction name the renderer plays ('sparkle', 'flyAway', 'drift',
  /// 'starBurst'…).
  final String reaction;
  final String sound;

  /// Always true in v2 — kept explicit so a future required beat is a
  /// deliberate, reviewable change, never an accident.
  final bool optional;
  final bool narrateOnMiss;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'interaction',
        't': t,
        'trigger': trigger.wire,
        'target': target,
        'reaction': reaction,
        'sound': sound,
        'optional': optional,
        'narrateOnMiss': narrateOnMiss,
      };

  factory InteractionCue.fromJson(Map<String, dynamic> j) => InteractionCue(
        t: SceneCue._t(j),
        target: j['target'] as String? ?? '',
        trigger: HotspotTrigger.parse(j['trigger'] as String?),
        reaction: j['reaction'] as String? ?? 'sparkle',
        sound: j['sound'] as String? ?? 'twinkle',
        optional: j['optional'] as bool? ?? true,
        narrateOnMiss: j['narrateOnMiss'] as bool? ?? false,
      );
}

// ── Scene ──────────────────────────────────────────────────────────────────

@immutable
class CinematicSceneV2 {
  const CinematicSceneV2({
    required this.id,
    required this.title,
    required this.narration,
    this.minDuration = 8,
    this.background = SceneBackground.sky,
    this.mood = SceneMood.calm,
    this.timeOfDay = SceneTimeOfDay.morning,
    this.weather = SceneWeather.clear,
    this.lighting = SceneLighting.warm,
    this.learningObjective = '',
    this.stage = const SceneStage(),
    this.cast = const <CastMember>[],
    this.camera,
    this.audio,
    this.transition = const SceneTransition(),
    this.particles = const <ParticleKind>[],
    this.cues = const <SceneCue>[],
  });

  final int id;
  final String title;
  final Narration narration;

  /// Minimum seconds on screen — a floor. Narration/cues may hold it longer.
  final double minDuration;

  final SceneBackground background;
  final SceneMood mood;
  final SceneTimeOfDay timeOfDay;
  final SceneWeather weather;
  final SceneLighting lighting;
  final String learningObjective;

  final SceneStage stage;
  final List<CastMember> cast;

  /// Opening camera move. Null → static frame (mid-scene [CameraCue]s still ok).
  final SceneCamera? camera;

  /// Per-scene audio overrides (music/ambience beds). Null → story defaults.
  final SceneAudio? audio;
  final SceneTransition transition;
  final List<ParticleKind> particles;

  /// The timeline, kept sorted by [SceneCue.t] after parse.
  final List<SceneCue> cues;

  /// The floor the [SceneClock] uses to know when a scene MAY advance —
  /// max(minDuration, last cue end). Real narration completion can push past
  /// this at runtime; interaction cues are excluded on purpose.
  double get scriptedDuration {
    double end = minDuration;
    for (final SceneCue cue in cues) {
      if (cue is InteractionCue) continue;
      final double cueEnd = cue.t + cue.span;
      if (cueEnd > end) end = cueEnd;
    }
    return end;
  }

  /// Only the optional hotspots (they're pulled out of the advance math).
  List<InteractionCue> get hotspots =>
      cues.whereType<InteractionCue>().toList(growable: false);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'minDuration': minDuration,
        'background': background.wire,
        'mood': mood.wire,
        'timeOfDay': timeOfDay.wire,
        'weather': weather.wire,
        'lighting': lighting.wire,
        'learningObjective': learningObjective,
        'stage': stage.toJson(),
        'cast': cast.map((CastMember c) => c.toJson()).toList(),
        if (camera != null) 'camera': camera!.toJson(),
        if (audio != null) 'audio': audio!.toJson(),
        'transition': transition.toJson(),
        'particles': particles.map((ParticleKind p) => p.wire).toList(),
        'narration': narration.toJson(),
        'cues': cues.map((SceneCue c) => c.toJson()).toList(),
      };

  factory CinematicSceneV2.fromJson(Map<String, dynamic> j) {
    final List<SceneCue> cues = ((j['cues'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic c) => SceneCue.parse(c as Map<String, dynamic>))
        .whereType<SceneCue>()
        .toList()
      ..sort((SceneCue a, SceneCue b) => a.t.compareTo(b.t));
    return CinematicSceneV2(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title'] as String? ?? '',
      minDuration: (j['minDuration'] as num?)?.toDouble() ?? 8,
      background: SceneBackground.parse(j['background'] as String?),
      mood: SceneMood.parse(j['mood'] as String?),
      timeOfDay: SceneTimeOfDay.parse(j['timeOfDay'] as String?),
      weather: SceneWeather.parse(j['weather'] as String?),
      lighting: SceneLighting.parse(j['lighting'] as String?),
      learningObjective: j['learningObjective'] as String? ?? '',
      stage: j['stage'] is Map<String, dynamic>
          ? SceneStage.fromJson(j['stage'] as Map<String, dynamic>)
          : const SceneStage(),
      cast: ((j['cast'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic c) => CastMember.fromJson(c as Map<String, dynamic>))
          .toList(),
      camera: j['camera'] is Map<String, dynamic>
          ? SceneCamera.fromJson(j['camera'] as Map<String, dynamic>)
          : null,
      audio: j['audio'] is Map<String, dynamic>
          ? SceneAudio.fromJson(j['audio'] as Map<String, dynamic>)
          : null,
      transition:
          SceneTransition.fromJson(j['transition'] as Map<String, dynamic>?),
      particles: ((j['particles'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic p) => ParticleKind.parse(p as String?))
          .whereType<ParticleKind>()
          .toList(),
      narration: Narration.fromJson(j['narration']),
      cues: cues,
    );
  }
}

// ── Story-level shell ──────────────────────────────────────────────────────

@immutable
class StoryCover {
  const StoryCover({
    this.emoji = '📖',
    this.image,
    this.palette = const <String>[],
  });

  final String emoji;
  final String? image;

  /// Hex strings (e.g. '#2EBDB5') for the card gradient / splash tint. The view
  /// maps them to Color; the model stays theme-agnostic.
  final List<String> palette;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'emoji': emoji,
        if (image != null) 'image': image,
        'palette': palette,
      };

  factory StoryCover.fromJson(Map<String, dynamic>? j) => StoryCover(
        emoji: j?['emoji'] as String? ?? '📖',
        image: j?['image'] as String?,
        palette: ((j?['palette'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic c) => c.toString())
            .toList(),
      );
}

@immutable
class AssetManifestEntry {
  const AssetManifestEntry({
    required this.id,
    required this.type,
    required this.url,
    this.bytes = 0,
    this.version = 1,
  });

  final String id;

  /// 'image' | 'rive' | 'lottie' | 'audio' | 'sprite' — decides how to preload.
  final String type;
  final String url;
  final int bytes;
  final int version;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'url': url,
        'bytes': bytes,
        'v': version,
      };

  factory AssetManifestEntry.fromJson(Map<String, dynamic> j) =>
      AssetManifestEntry(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'image',
        url: j['url'] as String? ?? '',
        bytes: (j['bytes'] as num?)?.toInt() ?? 0,
        version: (j['v'] as num?)?.toInt() ?? 1,
      );
}

@immutable
class CinematicStoryV2 {
  const CinematicStoryV2({
    required this.id,
    required this.slug,
    required this.title,
    required this.lang,
    required this.ageBand,
    required this.moral,
    required this.scenes,
    this.schemaVersion = '2.0',
    this.availableLangs = const <String>[],
    this.category = 'Moral Stories',
    this.concepts = const <String>[],
    this.estimatedDuration = 0,
    this.cover = const StoryCover(),
    this.audio = const StoryAudio(),
    this.reward = const StoryReward(),
    this.assetManifest = const <AssetManifestEntry>[],
  });

  final String schemaVersion;
  final String id;
  final String slug;
  final String title;

  /// BCP-47 language every text field is written in.
  final String lang;
  final List<String> availableLangs;
  final String ageBand;
  final String category;
  final List<String> concepts;
  final String moral;

  /// Seconds — for the library card; 0 = unknown (compute from scenes).
  final double estimatedDuration;
  final StoryCover cover;
  final StoryAudio audio;
  final StoryReward reward;
  final List<AssetManifestEntry> assetManifest;
  final List<CinematicSceneV2> scenes;

  /// Sum of every scene's scripted floor — a lower bound on runtime.
  double get scriptedDuration => scenes.fold<double>(
      0, (double a, CinematicSceneV2 s) => a + s.scriptedDuration,);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'id': id,
        'slug': slug,
        'title': title,
        'lang': lang,
        'availableLangs': availableLangs,
        'ageBand': ageBand,
        'category': category,
        'concepts': concepts,
        'moral': moral,
        'estimatedDuration': estimatedDuration,
        'cover': cover.toJson(),
        'audio': audio.toJson(),
        'reward': reward.toJson(),
        'assetManifest':
            assetManifest.map((AssetManifestEntry a) => a.toJson()).toList(),
        'scenes': scenes.map((CinematicSceneV2 s) => s.toJson()).toList(),
      };

  factory CinematicStoryV2.fromJson(Map<String, dynamic> j) => CinematicStoryV2(
        schemaVersion: j['schemaVersion'] as String? ?? '2.0',
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        title: j['title'] as String? ?? '',
        lang: j['lang'] as String? ?? 'en',
        availableLangs: ((j['availableLangs'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic l) => l.toString())
            .toList(),
        ageBand: j['ageBand'] as String? ?? 'junior',
        category: j['category'] as String? ?? 'Moral Stories',
        concepts: ((j['concepts'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic c) => c.toString())
            .toList(),
        moral: j['moral'] as String? ?? '',
        estimatedDuration: (j['estimatedDuration'] as num?)?.toDouble() ?? 0,
        cover: StoryCover.fromJson(j['cover'] as Map<String, dynamic>?),
        audio: StoryAudio.fromJson(j['audio'] as Map<String, dynamic>?),
        reward: StoryReward.fromJson(j['reward'] as Map<String, dynamic>?),
        assetManifest: ((j['assetManifest'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic a) =>
                AssetManifestEntry.fromJson(a as Map<String, dynamic>),)
            .toList(),
        scenes: ((j['scenes'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic s) =>
                CinematicSceneV2.fromJson(s as Map<String, dynamic>),)
            .toList(),
      );
}
