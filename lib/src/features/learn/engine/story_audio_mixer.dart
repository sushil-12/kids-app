import 'dart:math' as math;

import '../../../core/services/audio_service.dart';
import '../data/cinematic_story.dart' show MusicTrack;

/// (Negative) dB → linear gain. 0 dB → 1.0, −6 dB → ~0.501, −∞ → 0.
double duckGain(double db) => db <= -60 ? 0 : math.pow(10, db / 20).toDouble();

/// The device seam the mixer drives. Behind an interface so the mixer's bus +
/// duck bookkeeping is unit-testable with a fake sink, no audio plugins.
abstract interface class StoryAudioSink {
  void playMusicTrack(String track, double volume);
  void setMusicVolume(double volume);
  void playAmbienceBed(String bed, double volume);
  void stopAmbience();
  void playSfx(String name);
  Future<void> speakText(String text, String? lang);
  void stopSpeech();
}

/// Adapts the app-wide [AudioService] to the mixer's [StoryAudioSink].
class AudioServiceSink implements StoryAudioSink {
  AudioServiceSink(this._audio);
  final AudioService _audio;

  @override
  void playMusicTrack(String track, double volume) =>
      _audio.playMusic(track, volume: volume);

  @override
  void setMusicVolume(double volume) => _audio.setMusicVolume(volume);

  @override
  void playAmbienceBed(String bed, double volume) =>
      _audio.playAmbience(bed, volume: volume);

  @override
  void stopAmbience() => _audio.stopAmbience();

  @override
  void playSfx(String name) => _audio.sfx(_sfxByName(name));

  @override
  Future<void> speakText(String text, String? lang) =>
      _audio.speak(text, languageCode: lang);

  @override
  void stopSpeech() => _audio.stopSpeech();

  static Sfx _sfxByName(String name) => Sfx.values.firstWhere(
        (Sfx s) => s.name == name,
        orElse: () => Sfx.chime,
      );
}

/// A multi-bus story soundstage: independent music / ambience / speech / sfx
/// buses over one device [StoryAudioSink], with **ducking** — narration and
/// dialogue smoothly pull the music bed down while they speak and restore it
/// after (classic film dialogue clarity). The music bed can also crossfade to
/// a new track on an emotional beat (adaptive music).
///
/// The single on-device TTS engine can't voice two lines at once, so narration
/// and dialogue share the speech bus; both duck the music. Ambience is a second
/// looping bed. All bus/duck math is pure and unit-tested; playback delegates
/// to the sink.
class StoryAudioMixer {
  StoryAudioMixer(this._sink, {this.narrationDuckDb = -4});

  final StoryAudioSink _sink;

  /// Default duck applied while narration is spoken (dialogue carries its own).
  final double narrationDuckDb;

  double _musicBase = 0.6;
  String? _musicTrack;
  String? _ambienceBed;

  /// Active duck dB values (a stack, so overlapping speech nests correctly).
  final List<double> _ducks = <double>[];

  /// Multiplier the deepest active duck imposes on the music bus (1 = none).
  double get musicGain {
    double gain = 1;
    for (final double db in _ducks) {
      gain = math.min(gain, duckGain(db));
    }
    return gain;
  }

  /// The music bus's current effective volume (base × duck gain).
  double get musicVolume => (_musicBase * musicGain).clamp(0.0, 1.0);

  /// Set / crossfade the music bed. Re-plays only when the track changes; a
  /// same-track call just updates the (possibly ducked) volume.
  void music(MusicTrack track, double volume) {
    _musicBase = volume;
    if (track.wire != _musicTrack) {
      _musicTrack = track.wire;
      _sink.playMusicTrack(track.wire, musicVolume);
    } else {
      _sink.setMusicVolume(musicVolume);
    }
  }

  /// Set the ambience bed. No-op when it's already the active bed.
  void ambience(String bed, double volume) {
    if (bed == _ambienceBed) return;
    _ambienceBed = bed;
    _sink.playAmbienceBed(bed, volume);
  }

  void sfx(String name) => _sink.playSfx(name);

  /// Speak [text] on the speech bus, ducking the music by [duckDb] for the
  /// duration. Returns when speech completes and the bed is restored. A
  /// non-negative [duckDb] means no duck.
  Future<void> speak(String text, {double? duckDb, String? lang}) async {
    final double db = duckDb ?? narrationDuckDb;
    final bool ducking = db < 0;
    if (ducking) {
      _ducks.add(db);
      _sink.setMusicVolume(musicVolume);
    }
    try {
      await _sink.speakText(text, lang);
    } finally {
      if (ducking) {
        _ducks.remove(db);
        _sink.setMusicVolume(musicVolume);
      }
    }
  }

  /// Cut all speech and lift every duck (e.g. on scene skip / pause).
  void stopSpeech() {
    _sink.stopSpeech();
    if (_ducks.isNotEmpty) {
      _ducks.clear();
      _sink.setMusicVolume(musicVolume);
    }
  }
}
