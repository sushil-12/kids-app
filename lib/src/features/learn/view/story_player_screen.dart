import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/remote_illustration.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../data/cinematic_story.dart';
import '../engine/scene_painter.dart';
import '../engine/scene_particles.dart';
import '../view_model/learn_providers.dart';
import '../view_model/story_player_view_model.dart';

/// S· Story Player — plays a cinematic scene-script story: vector stage with
/// camera moves, TTS narration + subtitles, ambient particles, animated emoji
/// characters and no-fail tap/drag interactions. Ends on a reward card
/// (stars + coins + badge sticker).
class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<CinematicStory> async = ref.watch(cinematicStoryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // This screen's background is dark, unlike the rest of the app — flip
      // the status/nav bar icons light so they stay visible over it.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: async.when(
          loading: () => _LoadingView(message: l10n.contentLoading),
          error: (_, __) => _LoadingView(message: l10n.contentLoading),
          data: (CinematicStory story) => _PlayerView(story: story),
        ),
      ),
    );
  }
}

class _PlayerView extends ConsumerStatefulWidget {
  const _PlayerView({required this.story});

  final CinematicStory story;

  @override
  ConsumerState<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<_PlayerView>
    with TickerProviderStateMixin {
  /// Loops forever; drives particles + character idle/fly/hop motion.
  late final AnimationController _ambient;

  /// One forward pass per scene; drives the camera zoom/pan.
  late final AnimationController _camera;

  /// Short shake played on a wrong tap (no-fail wobble).
  late final AnimationController _shake;

  /// Guards stale narration futures after a scene change or skip.
  int _narrationTick = 0;
  bool _rewarded = false;

  CinematicStory get _story => widget.story;

  StoryPlayerViewModel get _vm =>
      ref.read(storyPlayerProvider(_story).notifier);

  /// Captured in [initState]: `ref` may not be used from [dispose], and audio
  /// MUST be stopped there or narration/music keeps playing after close.
  late final AudioService _audio;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioServiceProvider);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _camera = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_audio.playMusic(_story.music.wire));
      final StoryScene? scene = _vm.currentScene;
      if (scene != null) _enterScene(scene);
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _camera.dispose();
    _shake.dispose();
    _audio.stopMusic();
    _audio.stopSpeech();
    super.dispose();
  }

  void _enterScene(StoryScene scene) {
    _camera
      ..duration = Duration(
        milliseconds: (math.max(scene.minDuration, 6) * 1000).round(),
      )
      ..reset()
      ..forward();
    _precacheNextIllustration(scene);
    unawaited(_narrate(scene));
  }

  /// Warms the disk/memory cache for the next scene's illustration so it is
  /// on screen from the first frame instead of popping in mid-scene. Failures
  /// are ignored — the stage falls back to the vector look.
  void _precacheNextIllustration(StoryScene scene) {
    final int index = _story.scenes.indexOf(scene);
    if (index < 0 || index + 1 >= _story.scenes.length) return;
    final String? url = _story.scenes[index + 1].image;
    if (url == null) return;
    unawaited(
      precacheImage(
        illustrationProvider(url),
        context,
        onError: (Object error, StackTrace? stackTrace) {},
      ),
    );
  }

  Future<void> _narrate(StoryScene scene) async {
    final int tick = ++_narrationTick;
    // speak() awaits TTS completion; the delay enforces the scene's minimum
    // hold even when sound is off or narration is short.
    await Future.wait(<Future<void>>[
      _audio.speak(scene.narration, languageCode: _story.lang),
      Future<void>.delayed(
        Duration(milliseconds: (scene.minDuration * 1000).round()),
      ),
    ]);
    if (!mounted || tick != _narrationTick) return;
    _vm.onNarrationComplete();
  }

  void _skip() {
    _narrationTick++; // cancel the in-flight narration wait
    _audio.stopSpeech();
    _vm.skip();
  }

  void _onFinished() {
    if (_rewarded) return;
    _rewarded = true;
    final RewardsViewModel rewards = ref.read(rewardsProvider.notifier);
    rewards.addWallet(
      stars: _story.reward.stars,
      coins: _story.reward.coins,
    );
    rewards.awardById(_story.reward.badgeStickerId);
    _audio.sfx(Sfx.win);
    unawaited(_audio.speakPraise());
  }

  Sfx _sfxByName(String name) => Sfx.values.firstWhere(
        (Sfx s) => s.name == name,
        orElse: () => Sfx.chime,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StoryPlayerState state = ref.watch(storyPlayerProvider(_story));

    ref.listen(storyPlayerProvider(_story),
        (StoryPlayerState? prev, StoryPlayerState next) {
      if (next.phase == PlayerPhase.finished) {
        _audio.stopSpeech();
        _onFinished();
        return;
      }
      final bool sceneEntered = next.phase == PlayerPhase.narrating &&
          (prev == null ||
              prev.sceneIndex != next.sceneIndex ||
              prev.phase != PlayerPhase.narrating);
      if (sceneEntered) {
        _audio.stopSpeech();
        _enterScene(_story.scenes[next.sceneIndex]);
        return;
      }
      if (next.phase == PlayerPhase.interacting &&
          prev?.phase != PlayerPhase.interacting) {
        final String? hint = _story.scenes[next.sceneIndex].interaction?.hint;
        if (hint != null) {
          unawaited(_audio.speak(hint, languageCode: _story.lang));
        }
      }
      if (prev != null && next.wrongTapTick != prev.wrongTapTick) {
        _audio.sfx(Sfx.wobble);
        _shake.forward(from: 0);
      }
    });

    if (state.isFinished) {
      return _EndCard(
        story: _story,
        l10n: l10n,
        onReplay: () {
          _vm.replay();
        },
        onDone: () => context.pop(),
      );
    }

    final StoryScene scene = _story.scenes[state.sceneIndex];
    final SceneInteraction? interaction =
        state.phase == PlayerPhase.interacting ? scene.interaction : null;

    return Stack(
      children: <Widget>[
        // The cinematic stage (shaken gently on wrong taps).
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _shake,
            builder: (BuildContext context, Widget? child) {
              final double t = _shake.value;
              final double dx = math.sin(t * math.pi * 4) * 8 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              // Gentle cross-fade with a settle-down scale — the storybook
              // "page turn" feel instead of a hard swap.
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.03, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _SceneStage(
                key: ValueKey<int>(state.sceneIndex),
                scene: scene,
                interaction: interaction,
                ambient: _ambient,
                camera: _camera,
                onTapElement: (String id) {
                  final bool solved = _vm.tapTarget(id);
                  if (solved && scene.interaction != null) {
                    _audio.sfx(_sfxByName(scene.interaction!.sound));
                  }
                },
                onDropElement: (String targetId, String zoneId) {
                  final bool solved = _vm.dropOnZone(targetId, zoneId);
                  if (solved && scene.interaction != null) {
                    _audio.sfx(_sfxByName(scene.interaction!.sound));
                  }
                },
              ),
            ),
          ),
        ),

        // Top bar: close, progress dots, skip.
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
                      active: state.sceneIndex,
                    ),
                  ),
                ),
                _RoundButton(
                  icon: Icons.fast_forward_rounded,
                  onTap: _skip,
                ),
              ],
            ),
          ),
        ),

        // Subtitle / hint bar.
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _SubtitleBar(
                text: interaction?.hint ?? scene.narration,
                isHint: interaction != null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── The stage ────────────────────────────────────────────────────────────────

/// The stage renders in one of two modes:
///
/// - **Illustrated** — when the scene carries a backend illustration URL and
///   it has loaded (from cache or network), the art plays full-bleed under
///   the existing camera move (Ken Burns), with a bottom scrim for subtitle
///   legibility. The painted props/characters hide (the art depicts them);
///   only the interaction hotspots stay on top.
/// - **Vector fallback** — no URL, still loading, or offline: the procedural
///   painter stage with animated emoji characters, so the story always plays.
class _SceneStage extends StatefulWidget {
  const _SceneStage({
    super.key,
    required this.scene,
    required this.interaction,
    required this.ambient,
    required this.camera,
    required this.onTapElement,
    required this.onDropElement,
  });

  final StoryScene scene;

  /// Non-null only while the scene is waiting on it.
  final SceneInteraction? interaction;
  final Animation<double> ambient;
  final Animation<double> camera;
  final ValueChanged<String> onTapElement;
  final void Function(String targetId, String zoneId) onDropElement;

  @override
  State<_SceneStage> createState() => _SceneStageState();
}

class _SceneStageState extends State<_SceneStage> {
  IllustrationPreloader? _preloader;

  /// True once the illustration has a decoded frame — flips the layer stack
  /// from vector to illustrated. Never flips on error (silent fallback).
  bool _imageReady = false;

  @override
  void initState() {
    super.initState();
    final String? url = widget.scene.image;
    if (url != null) {
      _preloader = IllustrationPreloader(
        url: url,
        onReady: () {
          if (mounted) setState(() => _imageReady = true);
        },
      )..start();
    }
  }

  @override
  void dispose() {
    _preloader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoryScene scene = widget.scene;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: widget.camera,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeInOut.transform(widget.camera.value);
            final (double scale, Offset offset) = switch (scene.camera) {
              CameraEffect.none => (1.0, Offset.zero),
              CameraEffect.zoomIn => (1.0 + 0.12 * t, Offset.zero),
              CameraEffect.zoomOut => (1.12 - 0.12 * t, Offset.zero),
              CameraEffect.panLeft => (
                  1.1,
                  Offset(size.width * 0.05 * (2 * t - 1), 0),
                ),
              CameraEffect.panRight => (
                  1.1,
                  Offset(-size.width * 0.05 * (2 * t - 1), 0),
                ),
            };
            // Illustrated scenes get a small base zoom so Ken Burns pans
            // never reveal the image edge.
            final double base = _imageReady ? 1.08 : 1.0;
            return Transform.translate(
              offset: offset,
              child: Transform.scale(scale: scale * base, child: child),
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A tap anywhere off-target during an interaction still answers
            // with a gentle wobble, never a fail state.
            onTap: () => widget.onTapElement(''),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  child: CustomPaint(painter: ScenePainter(scene: scene)),
                ),
                // Full-bleed illustration; renders nothing until loaded, then
                // fades in over the vector stage.
                if (scene.image != null)
                  RepaintBoundary(
                    child: RemoteIllustration(url: scene.image!),
                  ),
                if (scene.image != null)
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _imageReady ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: <double>[0.55, 1],
                            colors: <Color>[
                              Colors.transparent,
                              AppColors.darkScrim,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: SceneParticlesPainter(
                      particles: scene.particles,
                      time: widget.ambient,
                    ),
                  ),
                ),
                for (final SceneProp prop in scene.props)
                  _StageElement(
                    id: prop.id,
                    x: prop.x,
                    y: prop.y,
                    extent: size.shortestSide * 0.22 * prop.scale,
                    interaction: widget.interaction,
                    onTap: widget.onTapElement,
                    onDrop: widget.onDropElement,
                    child: const SizedBox.expand(),
                  ),
                for (final SceneCharacter character in scene.characters)
                  _StageElement(
                    id: character.id,
                    x: character.x,
                    y: character.y,
                    extent: size.shortestSide * 0.2 * character.scale,
                    interaction: widget.interaction,
                    onTap: widget.onTapElement,
                    onDrop: widget.onDropElement,
                    // Over an illustration the art depicts the character, so
                    // the emoji hides and only the hotspot ring remains.
                    child: _imageReady
                        ? const SizedBox.expand()
                        : _AnimatedCharacter(
                            character: character,
                            ambient: widget.ambient,
                            fontSize:
                                size.shortestSide * 0.17 * character.scale,
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One positioned prop/character hit area. While an interaction targets it,
/// it glows; tap targets answer taps, drag targets become draggable and drop
/// zones accept them.
class _StageElement extends StatelessWidget {
  const _StageElement({
    required this.id,
    required this.x,
    required this.y,
    required this.extent,
    required this.interaction,
    required this.onTap,
    required this.onDrop,
    required this.child,
  });

  final String id;
  final double x;
  final double y;
  final double extent;
  final SceneInteraction? interaction;
  final ValueChanged<String> onTap;
  final void Function(String targetId, String zoneId) onDrop;
  final Widget child;

  bool get _isTarget => interaction?.target == id;
  bool get _isDropZone =>
      interaction?.type == InteractionType.drag && interaction?.dropZone == id;

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox(width: extent, height: extent, child: child);

    if (_isTarget || _isDropZone) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.yellow.withValues(alpha: 0.9),
            width: 3,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.yellow.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 4,
            ),
          ],
        ),
        child: content,
      );
    }

    if (_isTarget && interaction!.type == InteractionType.drag) {
      content = Draggable<String>(
        data: id,
        feedback: Opacity(opacity: 0.85, child: content),
        childWhenDragging: Opacity(opacity: 0.25, child: content),
        child: content,
      );
    } else if (_isDropZone) {
      // Capture before reassigning: the builder closure sees the *variable*,
      // and `content = DragTarget(...)` would make it build itself forever.
      final Widget zoneChild = content;
      content = DragTarget<String>(
        onAcceptWithDetails: (DragTargetDetails<String> details) =>
            onDrop(details.data, id),
        builder: (BuildContext context, List<String?> candidates, __) =>
            Transform.scale(
          scale: candidates.isNotEmpty ? 1.15 : 1.0,
          child: zoneChild,
        ),
      );
    } else {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(id),
        child: content,
      );
    }

    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: content,
    );
  }
}

/// A character emoji with its scripted idle/fly/hop/walk/bounce motion, driven
/// by the shared ambient loop.
class _AnimatedCharacter extends StatelessWidget {
  const _AnimatedCharacter({
    required this.character,
    required this.ambient,
    required this.fontSize,
  });

  final SceneCharacter character;
  final Animation<double> ambient;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Grounded contact shadow: stays put while the character hops or
          // flies above it, which is what sells the depth.
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
          _motionRig(),
        ],
      ),
    );
  }

  /// The scripted idle/fly/hop/walk/bounce transform rig; moves the emoji
  /// only, so the contact shadow stays grounded.
  Widget _motionRig() {
    return AnimatedBuilder(
      animation: ambient,
      builder: (BuildContext context, Widget? child) {
        final double t = ambient.value * 2 * math.pi;
        final (Offset offset, double angle, double scale) =
            switch (character.animation) {
          CharacterAnimation.idle => (
              Offset(0, math.sin(t) * 3),
              0.0,
              1.0,
            ),
          CharacterAnimation.fly => (
              Offset(math.sin(t * 0.5) * 6, math.sin(t * 2) * 8),
              math.sin(t) * 0.06,
              1.0,
            ),
          CharacterAnimation.hop => (
              Offset(0, -math.sin(t * 2).abs() * 12),
              0.0,
              1.0,
            ),
          CharacterAnimation.walk => (
              Offset(math.sin(t) * 8, 0),
              math.sin(t * 2) * 0.05,
              1.0,
            ),
          CharacterAnimation.bounce => (
              Offset.zero,
              0.0,
              1.0 + math.sin(t * 2).abs() * 0.08,
            ),
        };
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Center(
        child: Text(
          character.kind.emoji,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}

// ── Chrome ───────────────────────────────────────────────────────────────────

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
  const _SubtitleBar({required this.text, required this.isHint});

  final String text;
  final bool isHint;

  @override
  Widget build(BuildContext context) {
    // Storybook caption in the clay design language: a soft white card for
    // narration, the yellow "do this" card for hints. Sits over the stage's
    // bottom scrim, so it reads on any illustration.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isHint
            ? AppColors.yellow.withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isHint) ...<Widget>[
            const Text('👆', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
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

  final CinematicStory story;
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
                // Cover art when the backend provides it; the emoji sits
                // underneath and shows until (or unless) the image loads.
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Center(
                        child: Text(
                          story.coverEmoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                      if (story.coverImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: RemoteIllustration(url: story.coverImage!),
                        ),
                    ],
                  ),
                ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.cream,
                  ),
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
                      const SizedBox(height: 6),
                      Text(
                        l10n.storyRewardLine(
                          story.reward.stars,
                          story.reward.coins,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.cream,
                        ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
