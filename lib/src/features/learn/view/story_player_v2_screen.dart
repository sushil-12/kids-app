import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../data/cinematic_story.dart' show StoryScene, SceneProp;
import '../data/cinematic_story_v2.dart';
import '../engine/camera_rig.dart';
import '../engine/cue_scheduler.dart';
import '../engine/scene_clock.dart';
import '../engine/scene_painter.dart';
import '../engine/scene_particles.dart';
import '../engine/story_audio_mixer.dart';
import '../view_model/learn_providers.dart';
import '../view_model/story_director_view_model.dart';

/// The v2 cinematic story player — the "director track" experience.
///
/// One master [Ticker] pumps a [SceneClock] (the playhead); everything else
/// samples it: the [CueScheduler] fires timed beats (dialogue, character
/// actions, sfx, music, camera moves, holds), the [CameraRig] turns the scene's
/// keyframed camera into a per-frame transform, and narration is spoken over
/// the top. The story advances itself on the clock — optional tap "sparkles"
/// are pure delight and never gate progress (House Rule §5).
class StoryPlayerV2Screen extends ConsumerWidget {
  const StoryPlayerV2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<CinematicStoryV2> async =
        ref.watch(cinematicStoryV2Provider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: async.when(
          loading: () => _LoadingView(message: l10n.contentLoading),
          error: (_, __) => _LoadingView(message: l10n.contentLoading),
          data: (CinematicStoryV2 story) => _PlayerV2(story: story),
        ),
      ),
    );
  }
}

class _PlayerV2 extends ConsumerStatefulWidget {
  const _PlayerV2({required this.story});

  final CinematicStoryV2 story;

  @override
  ConsumerState<_PlayerV2> createState() => _PlayerV2State();
}

class _PlayerV2State extends ConsumerState<_PlayerV2>
    with TickerProviderStateMixin {
  /// The master ticker → pumps [_clock] each frame.
  late final Ticker _ticker;

  /// Loops forever; drives ambient particles + character idle motion.
  late final AnimationController _ambient;

  /// Repaints only the camera transform each frame (cheap, isolated).
  final ValueNotifier<double> _playhead = ValueNotifier<double>(0);

  late final AudioService _audio;
  late final StoryAudioMixer _mixer;

  // ── Per-scene runtime state ────────────────────────────────────────────
  SceneClock? _clock;
  CueScheduler? _scheduler;
  SceneCamera? _activeCamera;
  final Map<String, CharacterAction> _actions = <String, CharacterAction>{};
  String _caption = '';
  bool _advanced = false;
  bool _rewarded = false;

  double _lastTickSeconds = 0;
  PlaybackStatus _status = PlaybackStatus.cover;

  /// Guards TTS: a scene change or dialogue bumps this so a stale completion
  /// can't clear [_speaking] for the wrong line.
  int _speechId = 0;
  bool _speaking = false;

  CinematicStoryV2 get _story => widget.story;

  StoryDirectorViewModel get _vm =>
      ref.read(storyDirectorProvider(_story).notifier);

  CinematicSceneV2 get _scene =>
      _story.scenes[ref.read(storyDirectorProvider(_story)).sceneIndex.clamp(
            0,
            _story.scenes.length - 1,
          )];

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioServiceProvider);
    _mixer = StoryAudioMixer(AudioServiceSink(_audio));
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _ticker = createTicker(_onTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A short cover beat, then the film begins on its own.
      Timer(const Duration(milliseconds: 1800), () {
        if (mounted) _vm.begin();
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ambient.dispose();
    _playhead.dispose();
    _audio.stopMusic();
    _audio.stopAmbience();
    _mixer.stopSpeech();
    super.dispose();
  }

  // ── The clock loop ───────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final double now = elapsed.inMicroseconds / 1e6;
    final double dt = (now - _lastTickSeconds).clamp(0.0, 0.1);
    _lastTickSeconds = now;

    final SceneClock? clock = _clock;
    final CueScheduler? scheduler = _scheduler;
    if (clock == null || scheduler == null) return;
    if (_status != PlaybackStatus.playing) return;

    clock.advance(dt);
    for (final SceneCue cue in scheduler.advanceTo(clock.t)) {
      _dispatch(cue);
    }
    _playhead.value = clock.t;

    // Advance when the scripted floor is met AND nothing is still being
    // spoken. Optional interactions are never part of this condition.
    if (!_advanced && clock.reachedFloor && !_speaking) {
      _advanced = true;
      _vm.advance();
    }
  }

  // ── Scene lifecycle ──────────────────────────────────────────────────────

  void _enterScene(CinematicSceneV2 scene) {
    _clock = SceneClock(duration: scene.scriptedDuration)..play();
    _scheduler = CueScheduler(scene.cues)..reset();
    _activeCamera = scene.camera;
    _actions.clear();
    _advanced = false;
    _playhead.value = 0;

    _playAudioFor(scene);
    setState(() => _caption = scene.narration.text);
    unawaited(_speak(scene.narration.text));
  }

  /// Set the scene's music + ambience beds through the mixer (per-scene
  /// override falls back to the story defaults).
  void _playAudioFor(CinematicSceneV2 scene) {
    final MusicBed music = scene.audio?.music ?? _story.audio.music;
    _mixer.music(music.track, music.volume);
    final AmbienceBed ambience = scene.audio?.ambience ?? _story.audio.ambience;
    _mixer.ambience(ambience.bed, ambience.volume);
  }

  /// Speak on the mixer's speech bus (ducking the music) and gate scene
  /// advance on [_speaking] so a scene never cuts off mid-line. [duckDb] null
  /// uses the mixer's narration duck.
  Future<void> _speak(String text, {double? duckDb}) async {
    final int id = ++_speechId;
    _speaking = true;
    await _mixer.speak(text, duckDb: duckDb, lang: _story.lang);
    if (!mounted || id != _speechId) return;
    _speaking = false;
  }

  void _dispatch(SceneCue cue) {
    switch (cue) {
      case DialogueCue():
        setState(() => _caption = cue.text);
        unawaited(_speak(cue.text, duckDb: cue.duckMusicDb));
      case CharacterCue():
        setState(() => _actions[cue.target] = cue.action);
      case CameraCue():
        _activeCamera = cue.move; // sampled every frame; no rebuild needed
      case SfxCue():
        _mixer.sfx(cue.sound);
      case MusicCue():
        _mixer.music(cue.track, cue.volume); // adaptive crossfade on a beat
      case AmbientCue():
        _mixer.ambience(cue.bed, cue.volume);
      case CaptionCue():
        setState(() => _caption = cue.text);
      case PropCue():
      case HoldCue():
      case InteractionCue():
        break; // no timeline side-effect (hotspots are rendered, not fired)
    }
  }

  Sfx _sfxByName(String name) => Sfx.values.firstWhere(
        (Sfx s) => s.name == name,
        orElse: () => Sfx.chime,
      );

  Offset _resolveTarget(String id) {
    for (final CastMember c in _scene.cast) {
      if (c.id == id) return Offset(c.x, c.y);
    }
    return const Offset(0.5, 0.5); // unknown → no follow bias
  }

  void _onFinished() {
    if (_rewarded) return;
    _rewarded = true;
    _mixer.stopSpeech();
    final RewardsViewModel rewards = ref.read(rewardsProvider.notifier);
    rewards.addWallet(stars: _story.reward.stars, coins: _story.reward.coins);
    rewards.awardById(_story.reward.badgeStickerId);
    _audio.sfx(Sfx.win);
    unawaited(_audio.speakPraise());
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlaybackState playback = ref.watch(storyDirectorProvider(_story));
    _status = playback.status;

    ref.listen(storyDirectorProvider(_story),
        (PlaybackState? prev, PlaybackState next) {
      if (next.status == PlaybackStatus.ended) {
        _clock?.pause();
        _onFinished();
        return;
      }
      // Cover → playing, or a scene change → set up the next scene.
      final bool sceneEntered = next.status == PlaybackStatus.playing &&
          (prev == null ||
              prev.status == PlaybackStatus.cover ||
              prev.sceneIndex != next.sceneIndex);
      if (sceneEntered) {
        _mixer.stopSpeech();
        _speaking = false;
        _enterScene(_story.scenes[next.sceneIndex]);
        return;
      }
      // Pause / resume just gate the clock; the ticker keeps ticking.
      if (next.status == PlaybackStatus.paused) {
        _clock?.pause();
        _mixer.stopSpeech();
        _speaking = false;
      } else if (next.status == PlaybackStatus.playing &&
          prev?.status == PlaybackStatus.paused) {
        _clock?.play();
      }
    });

    if (playback.isEnded) {
      return _EndCard(
        story: _story,
        l10n: l10n,
        onReplay: _vm.replay,
        onDone: () => context.pop(),
      );
    }

    final CinematicSceneV2 scene = _story.scenes[playback.sceneIndex];

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.03, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: _V2Stage(
              key: ValueKey<int>(playback.sceneIndex),
              scene: scene,
              actions: _actions,
              ambient: _ambient,
              playhead: _playhead,
              camera: () => _activeCamera,
              resolveTarget: _resolveTarget,
              onSparkle: _onSparkleSound,
            ),
          ),
        ),

        // Top bar: close, progress dots, pause/play, skip.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                _RoundButton(
                  icon: Icons.close_rounded,
                  onTap: () => context.pop(),
                ),
                Expanded(
                  child: Center(
                    child: _ProgressDots(
                      count: _story.scenes.length,
                      active: playback.sceneIndex,
                    ),
                  ),
                ),
                _RoundButton(
                  icon: playback.status == PlaybackStatus.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onTap: _vm.togglePause,
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  icon: Icons.fast_forward_rounded,
                  onTap: _vm.skip,
                ),
              ],
            ),
          ),
        ),

        // Subtitle bar.
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _SubtitleBar(text: _caption),
            ),
          ),
        ),

        // Cover overlay — fades away as the film begins.
        IgnorePointer(
          ignoring: playback.status != PlaybackStatus.cover,
          child: AnimatedOpacity(
            opacity: playback.status == PlaybackStatus.cover ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: _CoverCard(story: _story, onPlay: _vm.begin),
          ),
        ),
      ],
    );
  }

  void _onSparkleSound(String sound) => _audio.sfx(_sfxByName(sound));
}

// ── The stage ─────────────────────────────────────────────────────────────

/// Renders one scene: vector background + props (offline baseline), ambient
/// particles, animated cast, and an optional-tap sparkle layer — all under one
/// camera transform driven by the playhead.
class _V2Stage extends StatefulWidget {
  const _V2Stage({
    super.key,
    required this.scene,
    required this.actions,
    required this.ambient,
    required this.playhead,
    required this.camera,
    required this.resolveTarget,
    required this.onSparkle,
  });

  final CinematicSceneV2 scene;
  final Map<String, CharacterAction> actions;
  final Animation<double> ambient;
  final ValueListenable<double> playhead;

  /// Read on demand so a mid-scene CameraCue swap is picked up without a rebuild.
  final SceneCamera? Function() camera;
  final Offset Function(String id) resolveTarget;
  final ValueChanged<String> onSparkle;

  @override
  State<_V2Stage> createState() => _V2StageState();
}

class _V2StageState extends State<_V2Stage> {
  static const CameraRig _rig = CameraRig();

  /// Live tap sparkles (fractional positions); each removes itself when done.
  final List<_SparkleSpec> _sparkles = <_SparkleSpec>[];
  int _sparkleId = 0;

  void _spawnSparkle(Offset fractional) {
    final InteractionCue? hotspot =
        widget.scene.hotspots.isEmpty ? null : widget.scene.hotspots.first;
    widget.onSparkle(hotspot?.sound ?? 'chime');
    final int id = _sparkleId++;
    setState(() => _sparkles.add(_SparkleSpec(id: id, at: fractional)));
  }

  /// Synthesize the v1 scene the vector [ScenePainter] draws from (background +
  /// flattened parallax props) — both are shared model types.
  StoryScene get _paintScene {
    final List<SceneProp> props = <SceneProp>[
      for (final StageLayer layer in widget.scene.stage.layers) ...layer.props,
    ];
    return StoryScene(
      id: widget.scene.id,
      title: widget.scene.title,
      background: widget.scene.background,
      narration: '',
      props: props,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        return ValueListenableBuilder<double>(
          valueListenable: widget.playhead,
          builder: (BuildContext context, double t, Widget? child) {
            final CameraFrame frame = _rig.frameAt(
              widget.camera(),
              t,
              resolveTarget: widget.resolveTarget,
            );
            return Transform(
              transform: frame.toMatrix4(size),
              child: child,
            );
          },
          child: RepaintBoundary(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // A tap anywhere adds a sparkle — pure delight, never blocking.
              onTapDown: (TapDownDetails d) => _spawnSparkle(
                Offset(
                  d.localPosition.dx / size.width,
                  d.localPosition.dy / size.height,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  RepaintBoundary(
                    child:
                        CustomPaint(painter: ScenePainter(scene: _paintScene)),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: SceneParticlesPainter(
                        particles: widget.scene.particles,
                        time: widget.ambient,
                      ),
                    ),
                  ),
                  for (final CastMember member in widget.scene.cast)
                    _V2Character(
                      member: member,
                      action: widget.actions[member.id] ?? CharacterAction.idle,
                      ambient: widget.ambient,
                      playhead: widget.playhead,
                      extent: size.shortestSide * 0.2 * member.scale,
                    ),
                  for (final _SparkleSpec spec in _sparkles)
                    _Sparkle(
                      key: ValueKey<int>(spec.id),
                      at: spec.at,
                      onDone: () => setState(() => _sparkles.remove(spec)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkleSpec {
  const _SparkleSpec({required this.id, required this.at});
  final int id;
  final Offset at;
}

/// A short expanding-and-fading star at a tap point.
class _Sparkle extends StatelessWidget {
  const _Sparkle({super.key, required this.at, required this.onDone});

  final Offset at;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(at.dx * 2 - 1, at.dy * 2 - 1),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        onEnd: onDone,
        builder: (BuildContext context, double v, Widget? child) {
          return Opacity(
            opacity: (1 - v).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.4 + v * 1.1,
              child: Transform.rotate(angle: v * 0.8, child: child),
            ),
          );
        },
        child: const Text('✨', style: TextStyle(fontSize: 44)),
      ),
    );
  }
}

/// A cast member: emoji with scripted action motion + an entrance slide, over a
/// grounded contact shadow that stays put while the character moves.
class _V2Character extends StatelessWidget {
  const _V2Character({
    required this.member,
    required this.action,
    required this.ambient,
    required this.playhead,
    required this.extent,
  });

  final CastMember member;
  final CharacterAction action;
  final Animation<double> ambient;
  final ValueListenable<double> playhead;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final double fontSize = extent * 0.85;
    return Align(
      alignment: Alignment(member.x * 2 - 1, member.y * 2 - 1),
      child: SizedBox(
        width: extent,
        height: extent,
        child: RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: playhead,
            builder: (BuildContext context, double t, Widget? child) {
              final Offset enter = _entranceOffset(t);
              return Transform.translate(
                offset: Offset(enter.dx * extent, enter.dy * extent),
                child: Opacity(
                  opacity: _entranceOpacity(t),
                  child: child,
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: fontSize * 0.9,
                    height: fontSize * 0.18,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(fontSize * 0.45, fontSize * 0.09),
                      ),
                    ),
                  ),
                ),
                _MotionRig(
                  action: action,
                  ambient: ambient,
                  facing: member.facing,
                  child: Center(
                    child: Text(
                      member.kind.emoji,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Slide in from the entrance edge over ~0.6s starting at `entrance.at`.
  Offset _entranceOffset(double t) {
    final CharacterEntrance? e = member.entrance;
    if (e == null) return Offset.zero;
    final double p = ((t - e.at) / 0.6).clamp(0.0, 1.0);
    final double d = (1 - Curves.easeOut.transform(p)) * 2.2;
    return switch (e.from) {
      'right' => Offset(d, 0),
      'top' => Offset(0, -d),
      'bottom' => Offset(0, d),
      _ => Offset(-d, 0), // 'left' / unknown
    };
  }

  double _entranceOpacity(double t) {
    final CharacterEntrance? e = member.entrance;
    if (e == null) return 1;
    return ((t - e.at) / 0.4).clamp(0.0, 1.0);
  }
}

/// Maps a [CharacterAction] to a looping transform driven by the ambient clock.
class _MotionRig extends StatelessWidget {
  const _MotionRig({
    required this.action,
    required this.ambient,
    required this.facing,
    required this.child,
  });

  final CharacterAction action;
  final Animation<double> ambient;
  final String facing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double mirror = facing == 'left' ? -1 : 1;
    return AnimatedBuilder(
      animation: ambient,
      builder: (BuildContext context, Widget? inner) {
        final double t = ambient.value * 2 * math.pi;
        final (Offset offset, double angle, double scale) = switch (action) {
          CharacterAction.idle => (Offset(0, math.sin(t) * 3), 0.0, 1.0),
          CharacterAction.fly => (
              Offset(math.sin(t * 0.5) * 6, math.sin(t * 2) * 8),
              math.sin(t) * 0.06,
              1.0,
            ),
          CharacterAction.hop || CharacterAction.jump => (
              Offset(0, -math.sin(t * 2).abs() * 12),
              0.0,
              1.0
            ),
          CharacterAction.walk => (
              Offset(math.sin(t) * 6, -math.sin(t * 2).abs() * 3),
              math.sin(t * 2) * 0.05,
              1.0,
            ),
          CharacterAction.run => (
              Offset(math.sin(t * 2) * 9, -math.sin(t * 4).abs() * 5),
              math.sin(t * 4) * 0.08,
              1.0,
            ),
          CharacterAction.bounce || CharacterAction.celebrate => (
              Offset(0, -math.sin(t * 2).abs() * 10),
              0.0,
              1.0 + math.sin(t * 2).abs() * 0.08
            ),
          CharacterAction.laugh => (
              Offset(0, math.sin(t * 3) * 3),
              math.sin(t * 3) * 0.12,
              1.0,
            ),
          CharacterAction.nod => (Offset.zero, math.sin(t * 2) * 0.14, 1.0),
          CharacterAction.shake => (Offset(math.sin(t * 6) * 5, 0), 0.0, 1.0),
          CharacterAction.cry || CharacterAction.fall => (
              Offset(0, math.sin(t) * 2),
              -0.2,
              1.0
            ),
          CharacterAction.sleep => (
              Offset(0, math.sin(t * 0.5) * 2),
              0.35,
              1.0
            ),
        };
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(mirror * scale, scale, 1),
              child: inner,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ── Chrome ──────────────────────────────────────────────────────────────────

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.story, required this.onPlay});

  final CinematicStoryV2 story;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onPlay,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.teal, AppColors.dark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(story.cover.emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 16),
              Text(
                story.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.yellow,
                size: 64,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= active
                  ? AppColors.yellow
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _SubtitleBar extends StatelessWidget {
  const _SubtitleBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
      ),
    );
  }
}

// ── End card ─────────────────────────────────────────────────────────────────

class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.story,
    required this.l10n,
    required this.onReplay,
    required this.onDone,
  });

  final CinematicStoryV2 story;
  final AppLocalizations l10n;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.purple, AppColors.dark],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(story.cover.emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 12),
                Text(
                  l10n.storyTheEnd,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  story.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.cream),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '💡 ${story.moral}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '⭐ ${story.reward.stars}',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: AppColors.yellow),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            '🪙 ${story.reward.coins}',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: AppColors.yellow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: onReplay,
                      child: Text(
                        l10n.storyWatchAgain,
                        style: const TextStyle(color: AppColors.cream),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                      ),
                      onPressed: onDone,
                      child: Text(
                        l10n.storyAllDone,
                        style: const TextStyle(color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.yellow),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
