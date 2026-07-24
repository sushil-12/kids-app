import 'package:brightmind_kids/src/core/services/sound_settings_store.dart';
import 'package:brightmind_kids/src/features/learn/view/story_player_v2_screen.dart';
import 'package:brightmind_kids/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sound off → [AudioService] no-ops before touching TTS/audio plugins, so the
/// player can be pumped in a widget test without plugin mocks.
class _SilentSoundStore implements SoundSettingsStore {
  @override
  SoundSettings read() => const SoundSettings(soundEnabled: false);

  @override
  void save(SoundSettings settings) {}
}

Widget _harness() => ProviderScope(
      overrides: <Override>[
        soundSettingsStoreProvider.overrideWithValue(_SilentSoundStore()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StoryPlayerV2Screen(),
      ),
    );

void main() {
  testWidgets('shows the cover, then auto-plays the first scene', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    // Resolve the FutureProvider that serves the sample story.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Cover card is up with the story title.
    expect(find.text('The Hare and the Tortoise'), findsWidgets);

    // Auto-begin fires after ~1.8s; the first scene's narration becomes the
    // subtitle — proof the cover → play → enterScene pipeline ran end to end.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('golden morning'),
      findsOneWidget,
    );
    expect(find.byType(StoryPlayerV2Screen), findsOneWidget);
    // The player survives continued playback (ticker + cues) without throwing.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
