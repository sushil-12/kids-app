import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/learn/data/learn_content.dart';
import '../../l10n/app_localizations.dart';
import '../router/locale_controller.dart';
import '../theme/app_colors.dart';
import 'sound_settings_store.dart';

/// A short sound effect. Files live in `assets/audio/<file>` and are dropped in
/// later (see assets/audio/README.md); until then playback is a graceful no-op.
enum Sfx { pop, plop, chime, flip, wobble, win, tap }

extension on Sfx {
  String get file => switch (this) {
        Sfx.pop => 'pop.mp3',
        Sfx.plop => 'plop.mp3',
        Sfx.chime => 'chime.mp3',
        Sfx.flip => 'flip.mp3',
        Sfx.wobble => 'wobble.mp3',
        Sfx.win => 'win.mp3',
        Sfx.tap => 'tap.mp3',
      };
}

/// The app's single voice + sound-effects engine. Spoken content uses on-device
/// text-to-speech (localized en/hi), so no recorded voice files are needed;
/// short SFX use a small pool of [AudioPlayer]s.
///
/// State (the master enable switch, the active locale) is read at **call time**,
/// so this service is created once and never needs rebuilding.
class AudioService {
  AudioService(this._ref);

  final Ref _ref;
  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _pool =
      List<AudioPlayer>.generate(4, (_) => AudioPlayer());
  int _next = 0;
  bool _ttsConfigured = false;

  /// Bumped by [stopSpeech]/[speak] so an in-flight `speak()` (they await
  /// several platform calls before actually talking) aborts instead of
  /// starting speech *after* it was stopped — e.g. when a screen closes.
  int _speechSession = 0;

  /// Cached so we don't probe the bundle / reload strings on every interaction.
  final Map<String, bool> _sfxAvailable = <String, bool>{};
  final Map<String, AppLocalizations> _l10nCache = <String, AppLocalizations>{};

  bool get _enabled => _ref.read(soundSettingsProvider).soundEnabled;

  /// The active locale, normalised to a supported one (`en` / `hi`).
  Locale get _locale {
    final Locale raw = _ref.read(localeControllerProvider) ??
        PlatformDispatcher.instance.locale;
    return raw.languageCode == 'hi' ? const Locale('hi') : const Locale('en');
  }

  bool get _isHindi => _locale.languageCode == 'hi';

  // ---- Speech -------------------------------------------------------------

  /// Speaks [text] in the active language. Silent if sound is off, the text is
  /// empty, or the device has no TTS engine.
  ///
  /// Pass [languageCode] ('en' / 'hi') to override the app locale — e.g. story
  /// narration is spoken in the story's own language, whatever the UI is set to.
  Future<void> speak(String text, {String? languageCode}) async {
    if (!_enabled || text.trim().isEmpty) return;
    final int session = ++_speechSession;
    try {
      if (!_ttsConfigured) {
        await _tts.awaitSpeakCompletion(true);
        _ttsConfigured = true;
      }
      final bool hindi = languageCode == null ? _isHindi : languageCode == 'hi';
      await _tts.stop();
      await _tts.setLanguage(hindi ? 'hi-IN' : 'en-US');
      await _tts.setSpeechRate(0.42); // slower & clearer for young children
      await _tts.setPitch(1.1); // warm, friendly tone
      if (session != _speechSession) return; // stopped while configuring
      await _tts.speak(text);
    } catch (_) {
      // No usable TTS engine — stay silent rather than crash.
    }
  }

  /// "A for Apple" (en) / "A — सेब" (hi), driven by the lesson + l10n connector.
  Future<void> speakLetter(AbcLesson lesson) async {
    if (!_enabled) return;
    final AppLocalizations l10n = await _l10n();
    final String word =
        _isHindi && lesson.wordHi.isNotEmpty ? lesson.wordHi : lesson.word;
    await speak(l10n.abcLetterForWord(lesson.letter, word));
  }

  /// Speaks a palette color's name ("red", "लाल"). No-op for unnamed swatches.
  Future<void> speakColor(Color color) async {
    if (!_enabled) return;
    final AppLocalizations l10n = await _l10n();
    final String? name = _colorName(color, l10n);
    if (name != null) await speak(name);
  }

  /// Speaks a count. TTS reads the digit in the active language.
  Future<void> speakNumber(int n) => speak('$n');

  /// A short, encouraging callout for any "you finished it" moment.
  Future<void> speakPraise() async {
    if (!_enabled) return;
    final AppLocalizations l10n = await _l10n();
    await speak(l10n.gameWinTitle);
  }

  void stopSpeech() {
    _speechSession++; // abort any speak() still configuring the engine
    unawaited(_tts.stop());
  }

  Future<AppLocalizations> _l10n() async {
    final String code = _locale.languageCode;
    return _l10nCache[code] ??=
        await AppLocalizations.delegate.load(Locale(code));
  }

  String? _colorName(Color color, AppLocalizations l10n) {
    final int argb = color.toARGB32();
    if (argb == AppColors.coral.toARGB32()) return l10n.colorRed;
    if (argb == AppColors.orange.toARGB32()) return l10n.colorOrange;
    if (argb == AppColors.yellow.toARGB32()) return l10n.colorYellow;
    if (argb == AppColors.green.toARGB32()) return l10n.colorGreen;
    if (argb == AppColors.teal.toARGB32()) return l10n.colorTeal;
    if (argb == AppColors.blue.toARGB32()) return l10n.colorBlue;
    if (argb == AppColors.purple.toARGB32()) return l10n.colorPurple;
    if (argb == AppColors.pink.toARGB32()) return l10n.colorPink;
    return null;
  }

  // ---- Sound effects ------------------------------------------------------

  /// Plays a short effect, fire-and-forget. Safe when the asset is missing.
  void sfx(Sfx kind) {
    if (!_enabled) return;
    unawaited(_playSfx(kind));
  }

  Future<void> _playSfx(Sfx kind) async {
    final String file = kind.file;
    if (!await _isSfxAvailable(file)) return;
    try {
      final AudioPlayer player = _pool[_next];
      _next = (_next + 1) % _pool.length;
      await player.stop();
      await player.play(AssetSource('audio/$file'));
    } catch (_) {
      // Ignore playback errors so a bad file never breaks the UI.
    }
  }

  Future<bool> _isSfxAvailable(String file) async {
    final bool? known = _sfxAvailable[file];
    if (known != null) return known;
    try {
      await rootBundle.load('assets/audio/$file');
      return _sfxAvailable[file] = true;
    } catch (_) {
      return _sfxAvailable[file] = false;
    }
  }

  // ---- Background music -----------------------------------------------------
  // One dedicated looping player, separate from the SFX pool so a music track
  // never steals a pool slot. Tracks live in assets/audio/music/<name>.mp3;
  // a missing file is a graceful no-op like SFX.

  AudioPlayer? _music;

  /// Same idea as [_speechSession]: [playMusic] awaits asset probing + player
  /// setup, and a stop that lands in that window must win.
  int _musicSession = 0;

  /// Current music-bus volume, so [setMusicVolume] (ducking) has a level to
  /// restore toward and [playMusic] starts at the right level.
  double _musicVolume = 0.3;

  /// Starts (or switches to) a looping background track. [volume] defaults to a
  /// gentle level so narration stays clearly audible above it; the story mixer
  /// passes the track's authored volume instead.
  Future<void> playMusic(String track, {double volume = 0.3}) async {
    if (!_enabled) return;
    _musicVolume = volume.clamp(0.0, 1.0);
    final int session = ++_musicSession;
    final String file = 'music/$track.mp3';
    if (!await _isSfxAvailable(file)) return;
    try {
      final AudioPlayer player = _music ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_musicVolume);
      if (session != _musicSession) return; // stopped while setting up
      await player.play(AssetSource('audio/$file'));
    } catch (_) {
      // Ignore playback errors so a bad file never breaks the UI.
    }
  }

  /// Sets the music-bus volume live — used by the story mixer to duck the bed
  /// under narration/dialogue and restore it after.
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    final AudioPlayer? player = _music;
    if (player == null) return;
    try {
      await player.setVolume(_musicVolume);
    } catch (_) {
      // Ignore — a missing/So-far-unstarted track has nothing to set.
    }
  }

  void stopMusic() {
    _musicSession++; // abort any playMusic() still setting up
    final AudioPlayer? player = _music;
    if (player != null) unawaited(player.stop());
  }

  // ---- Ambience -------------------------------------------------------------
  // A second looping player, independent of music, for the environment bed
  // (meadow, pond, rain…). Files live in assets/audio/ambience/<bed>.mp3; a
  // missing file is a graceful no-op like music/SFX.

  AudioPlayer? _ambience;
  int _ambienceSession = 0;

  Future<void> playAmbience(String bed, {double volume = 0.35}) async {
    if (!_enabled) return;
    final int session = ++_ambienceSession;
    final String file = 'ambience/$bed.mp3';
    if (!await _isSfxAvailable(file)) return;
    try {
      final AudioPlayer player = _ambience ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume.clamp(0.0, 1.0));
      if (session != _ambienceSession) return;
      await player.play(AssetSource('audio/$file'));
    } catch (_) {
      // Ignore playback errors so a bad file never breaks the UI.
    }
  }

  void stopAmbience() {
    _ambienceSession++;
    final AudioPlayer? player = _ambience;
    if (player != null) unawaited(player.stop());
  }

  void dispose() {
    unawaited(_tts.stop());
    for (final AudioPlayer player in _pool) {
      unawaited(player.dispose());
    }
    final AudioPlayer? music = _music;
    if (music != null) unawaited(music.dispose());
    final AudioPlayer? ambience = _ambience;
    if (ambience != null) unawaited(ambience.dispose());
  }
}

/// App-wide audio engine. Kept alive for the whole session.
final audioServiceProvider = Provider<AudioService>((Ref ref) {
  final AudioService service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});
