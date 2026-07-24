import 'package:brightmind_kids/src/features/learn/data/cinematic_story.dart'
    show MusicTrack;
import 'package:brightmind_kids/src/features/learn/engine/story_audio_mixer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every device call so the mixer's bus + duck bookkeeping can be
/// asserted without audio plugins.
class _FakeSink implements StoryAudioSink {
  final List<String> log = <String>[];
  double musicVolume = -1;
  String? music;
  String? ambience;

  @override
  void playMusicTrack(String track, double volume) {
    music = track;
    musicVolume = volume;
    log.add('music:$track@${volume.toStringAsFixed(3)}');
  }

  @override
  void setMusicVolume(double volume) {
    musicVolume = volume;
    log.add('vol@${volume.toStringAsFixed(3)}');
  }

  @override
  void playAmbienceBed(String bed, double volume) {
    ambience = bed;
    log.add('amb:$bed');
  }

  @override
  void stopAmbience() => log.add('amb:stop');

  @override
  void playSfx(String name) => log.add('sfx:$name');

  @override
  Future<void> speakText(String text, String? lang) async => log.add('say:$text');

  @override
  void stopSpeech() => log.add('speech:stop');
}

void main() {
  group('duckGain', () {
    test('0 dB is unity, −6 dB halves, deep ducks approach silence', () {
      expect(duckGain(0), 1.0);
      expect(duckGain(-6), closeTo(0.501, 0.002));
      expect(duckGain(-60), 0);
    });
  });

  group('StoryAudioMixer', () {
    test('music plays on track change, only re-levels on same track', () {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink);

      mixer.music(MusicTrack.playful, 0.6);
      expect(sink.music, 'playful');
      expect(sink.musicVolume, closeTo(0.6, 1e-9));

      sink.log.clear();
      mixer.music(MusicTrack.playful, 0.8); // same track, new level
      expect(sink.log, <String>['vol@0.800']);

      mixer.music(MusicTrack.calm, 0.5); // new track → replay
      expect(sink.music, 'calm');
    });

    test('ambience is set once per bed change', () {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink)
        ..ambience('meadow', 0.4)
        ..ambience('meadow', 0.4); // no-op
      expect(sink.log.where((String s) => s.startsWith('amb:')), <String>[
        'amb:meadow',
      ]);
      mixer.ambience('pond', 0.4);
      expect(sink.ambience, 'pond');
    });

    test('speak ducks the music bed by the given dB and restores after', () async {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink);
      mixer.music(MusicTrack.playful, 0.6);
      sink.log.clear();

      await mixer.speak('I am the fastest!', duckDb: -6);

      // Duck down to 0.6 * ~0.501, speak, restore to 0.6.
      expect(sink.log.first, startsWith('vol@'));
      expect(sink.musicVolume, closeTo(0.6, 1e-9)); // restored
      expect(sink.log, contains('say:I am the fastest!'));
      // A duck value was applied mid-line, below base.
      final double ducked = 0.6 * duckGain(-6);
      expect(sink.log, contains('vol@${ducked.toStringAsFixed(3)}'));
    });

    test('a non-negative duck does not touch the music level', () async {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink);
      mixer.music(MusicTrack.playful, 0.6);
      sink.log.clear();

      await mixer.speak('hello', duckDb: 0);
      expect(sink.log, <String>['say:hello']); // no vol changes
    });

    test('musicVolume reflects the deepest active duck', () {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink);
      mixer.music(MusicTrack.playful, 0.8);
      expect(mixer.musicVolume, closeTo(0.8, 1e-9));
      expect(mixer.musicGain, 1.0);
    });

    test('stopSpeech lifts any active duck and restores the bed', () async {
      final _FakeSink sink = _FakeSink();
      final StoryAudioMixer mixer = StoryAudioMixer(sink);
      mixer.music(MusicTrack.playful, 0.6);
      // Start a duck without awaiting completion, then stop.
      final Future<void> speaking = mixer.speak('long line', duckDb: -8);
      mixer.stopSpeech();
      await speaking;
      expect(sink.musicVolume, closeTo(0.6, 1e-9)); // fully restored
    });
  });
}
