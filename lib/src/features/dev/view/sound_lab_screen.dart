import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/sound_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../learn/data/learn_content.dart';

/// Developer tool (reached from Settings) to audition every sound the app makes
/// — each SFX and each kind of spoken voice line — on a real device, without
/// having to play through games to trigger them. Labels are intentionally plain
/// English: this screen is for grown-ups/devs, never shown to children.
class SoundLabScreen extends ConsumerWidget {
  const SoundLabScreen({super.key});

  // A few palette swatches whose names AudioService knows how to speak.
  static const List<(String, Color)> _colors = <(String, Color)>[
    ('red', AppColors.coral),
    ('orange', AppColors.orange),
    ('yellow', AppColors.yellow),
    ('green', AppColors.green),
    ('teal', AppColors.teal),
    ('blue', AppColors.blue),
    ('purple', AppColors.purple),
    ('pink', AppColors.pink),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioService audio = ref.read(audioServiceProvider);
    final bool enabled = ref.watch(
      soundSettingsProvider.select((SoundSettings s) => s.soundEnabled),
    );
    const List<AbcLesson> lessons = LearnFallbacks.abcLessons;

    return Scaffold(
      appBar: AppBar(title: const Text('Sound Lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Sound is gated by the master switch — make it obvious when muted,
          // and let the dev flip it without leaving the screen.
          if (!enabled)
            Card(
              color: AppColors.yellow.withValues(alpha: 0.25),
              child: ListTile(
                leading: const Icon(Icons.volume_off),
                title: const Text('Sound is OFF'),
                subtitle:
                    const Text('Everything below is silent until enabled.'),
                trailing: FilledButton(
                  onPressed: () => ref
                      .read(soundSettingsProvider.notifier)
                      .setSoundEnabled(true),
                  child: const Text('Enable'),
                ),
              ),
            ),
          const _SectionHeader('Sound effects'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final Sfx kind in Sfx.values)
                ActionChip(
                  avatar: const Icon(Icons.graphic_eq, size: 18),
                  label: Text(kind.name),
                  onPressed: () => audio.sfx(kind),
                ),
            ],
          ),
          const _SectionHeader('Voice — letters'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final AbcLesson lesson in lessons)
                ActionChip(
                  label: Text('${lesson.letter} · ${lesson.word}'),
                  onPressed: () => audio.speakLetter(lesson),
                ),
            ],
          ),
          const _SectionHeader('Voice — colors'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final (String label, Color color) in _colors)
                ActionChip(
                  avatar: CircleAvatar(backgroundColor: color, radius: 9),
                  label: Text(label),
                  onPressed: () => audio.speakColor(color),
                ),
            ],
          ),
          const _SectionHeader('Voice — numbers'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (int n = 1; n <= 10; n++)
                ActionChip(
                  label: Text('$n'),
                  onPressed: () => audio.speakNumber(n),
                ),
            ],
          ),
          const _SectionHeader('Voice — praise'),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.celebration),
              label: const Text('Say praise'),
              onPressed: audio.speakPraise,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tip: switch the app language in Settings, then replay a letter to '
            'hear it in Hindi (e.g. "A — सेब").',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
