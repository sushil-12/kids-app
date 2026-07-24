import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cinematic_story_v2.dart';

/// Where the whole playthrough is. The scene *timeline* (cues, clock, camera)
/// is driven frame-by-frame in the player widget; this view-model owns only the
/// coarse playthrough state so the view + Riverpod stay the source of truth for
/// "which scene, playing or not, finished or not".
enum PlaybackStatus { cover, playing, paused, ended }

@immutable
class PlaybackState {
  const PlaybackState({required this.sceneIndex, required this.status});

  final int sceneIndex;
  final PlaybackStatus status;

  bool get isEnded => status == PlaybackStatus.ended;
  bool get isPlaying => status == PlaybackStatus.playing;

  PlaybackState copyWith({int? sceneIndex, PlaybackStatus? status}) =>
      PlaybackState(
        sceneIndex: sceneIndex ?? this.sceneIndex,
        status: status ?? this.status,
      );
}

/// Drives one v2 story playthrough. Keyed by the story document itself, so the
/// notifier lives exactly as long as the player screen watches it.
class StoryDirectorViewModel
    extends AutoDisposeFamilyNotifier<PlaybackState, CinematicStoryV2> {
  CinematicStoryV2 get story => arg;

  CinematicSceneV2? get currentScene => state.sceneIndex < story.scenes.length
      ? story.scenes[state.sceneIndex]
      : null;

  @override
  PlaybackState build(CinematicStoryV2 arg) => PlaybackState(
        sceneIndex: 0,
        status:
            arg.scenes.isEmpty ? PlaybackStatus.ended : PlaybackStatus.cover,
      );

  /// Leave the cover card and start the film.
  void begin() {
    if (state.status == PlaybackStatus.cover) {
      state = state.copyWith(status: PlaybackStatus.playing);
    }
  }

  void pause() {
    if (state.status == PlaybackStatus.playing) {
      state = state.copyWith(status: PlaybackStatus.paused);
    }
  }

  void resume() {
    if (state.status == PlaybackStatus.paused) {
      state = state.copyWith(status: PlaybackStatus.playing);
    }
  }

  void togglePause() {
    switch (state.status) {
      case PlaybackStatus.playing:
        pause();
      case PlaybackStatus.paused:
        resume();
      case PlaybackStatus.cover:
      case PlaybackStatus.ended:
        break;
    }
  }

  /// The current scene reached its end (clock floor met AND narration done) —
  /// advance to the next scene, or finish. Optional interactions never call
  /// this; the story drives itself.
  void advance() {
    if (state.isEnded) return;
    if (state.sceneIndex + 1 >= story.scenes.length) {
      state = state.copyWith(status: PlaybackStatus.ended);
    } else {
      state = PlaybackState(
        sceneIndex: state.sceneIndex + 1,
        status: PlaybackStatus.playing,
      );
    }
  }

  /// Child/parent taps "skip this scene" — same effect as a natural finish.
  void skip() => advance();

  /// Parent-gated jump straight to the end card.
  void end() {
    if (!state.isEnded) {
      state = state.copyWith(status: PlaybackStatus.ended);
    }
  }

  /// "Watch again" from the end card.
  void replay() {
    state = PlaybackState(
      sceneIndex: 0,
      status:
          story.scenes.isEmpty ? PlaybackStatus.ended : PlaybackStatus.playing,
    );
  }
}

final storyDirectorProvider = NotifierProvider.autoDispose
    .family<StoryDirectorViewModel, PlaybackState, CinematicStoryV2>(
  StoryDirectorViewModel.new,
);
