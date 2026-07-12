import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cinematic_story.dart';

/// Where the player is inside the current scene.
enum PlayerPhase {
  /// Narration is being spoken / the scene is holding for its minDuration.
  narrating,

  /// Waiting for the child to complete the scene's tap/drag interaction.
  interacting,

  /// All scenes done — show the reward end card.
  finished,
}

/// Immutable player progress. The view drives timing (TTS + minDuration) and
/// calls intent methods; the view-model owns what happens next.
@immutable
class StoryPlayerState {
  const StoryPlayerState({
    required this.sceneIndex,
    required this.phase,
    this.wrongTapTick = 0,
  });

  final int sceneIndex;
  final PlayerPhase phase;

  /// Bumped on every wrong tap so the view can wobble the stage — there are
  /// no fail states (House Rule §5), just a gentle nudge.
  final int wrongTapTick;

  bool get isFinished => phase == PlayerPhase.finished;

  StoryPlayerState copyWith({
    int? sceneIndex,
    PlayerPhase? phase,
    int? wrongTapTick,
  }) =>
      StoryPlayerState(
        sceneIndex: sceneIndex ?? this.sceneIndex,
        phase: phase ?? this.phase,
        wrongTapTick: wrongTapTick ?? this.wrongTapTick,
      );
}

/// Drives one story playthrough. Keyed by the story document itself (the
/// provider instance lives exactly as long as the player screen watches it).
class StoryPlayerViewModel
    extends AutoDisposeFamilyNotifier<StoryPlayerState, CinematicStory> {
  CinematicStory get story => arg;

  StoryScene? get currentScene =>
      state.sceneIndex < story.scenes.length ? story.scenes[state.sceneIndex] : null;

  @override
  StoryPlayerState build(CinematicStory arg) => StoryPlayerState(
        sceneIndex: 0,
        phase: arg.scenes.isEmpty ? PlayerPhase.finished : PlayerPhase.narrating,
      );

  /// Narration (TTS) finished and the scene's minDuration elapsed. Either the
  /// scene blocks on its interaction, or we move on.
  void onNarrationComplete() {
    if (state.phase != PlayerPhase.narrating) return;
    if (currentScene?.interaction != null) {
      state = state.copyWith(phase: PlayerPhase.interacting);
    } else {
      _advance();
    }
  }

  /// The child tapped the prop/character with [id]. Returns true when it
  /// solves the scene's tap interaction (the view plays the success SFX and
  /// the scene advances); a wrong tap only wobbles.
  bool tapTarget(String id) {
    final SceneInteraction? interaction = currentScene?.interaction;
    if (state.phase != PlayerPhase.interacting ||
        interaction == null ||
        interaction.type != InteractionType.tap) {
      return false;
    }
    if (id == interaction.target) {
      _advance();
      return true;
    }
    state = state.copyWith(wrongTapTick: state.wrongTapTick + 1);
    return false;
  }

  /// The child dropped [targetId] onto [zoneId]. Returns true when it solves
  /// the scene's drag interaction.
  bool dropOnZone(String targetId, String zoneId) {
    final SceneInteraction? interaction = currentScene?.interaction;
    if (state.phase != PlayerPhase.interacting ||
        interaction == null ||
        interaction.type != InteractionType.drag) {
      return false;
    }
    if (targetId == interaction.target && zoneId == interaction.dropZone) {
      _advance();
      return true;
    }
    state = state.copyWith(wrongTapTick: state.wrongTapTick + 1);
    return false;
  }

  /// Parent/child skips ahead (also unblocks a stuck interaction).
  void skip() {
    if (state.isFinished) return;
    _advance();
  }

  /// Restart from the first scene ("Watch again").
  void replay() {
    state = StoryPlayerState(
      sceneIndex: 0,
      phase: story.scenes.isEmpty ? PlayerPhase.finished : PlayerPhase.narrating,
    );
  }

  void _advance() {
    if (state.sceneIndex + 1 >= story.scenes.length) {
      state = state.copyWith(phase: PlayerPhase.finished);
    } else {
      state = StoryPlayerState(
        sceneIndex: state.sceneIndex + 1,
        phase: PlayerPhase.narrating,
        wrongTapTick: state.wrongTapTick,
      );
    }
  }
}

final storyPlayerProvider = NotifierProvider.autoDispose
    .family<StoryPlayerViewModel, StoryPlayerState, CinematicStory>(
  StoryPlayerViewModel.new,
);
