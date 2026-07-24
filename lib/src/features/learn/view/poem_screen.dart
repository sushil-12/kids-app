import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';
import '../data/learn_content.dart';
import '../view_model/learn_providers.dart';

const List<String> _kTopics = <String>[
  'Animals',
  'Seasons',
  'Numbers',
  'Colors',
  'Nature',
];

const List<String> _kTopicEmojis = <String>[
  '🐾',
  '🌤️',
  '🔢',
  '🎨',
  '🌿',
];

/// S· Poem Screen — select a topic, read an AI-generated rhyming poem.
class PoemScreen extends ConsumerStatefulWidget {
  const PoemScreen({super.key});

  @override
  ConsumerState<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends ConsumerState<PoemScreen> {
  String _topic = _kTopics.first;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<KidsPoem> async = ref.watch(poemProvider(_topic));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(poemRefreshProvider.notifier).update((int n) => n + 1);
        },
        backgroundColor: AppColors.purple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 2.5),
        ),
        icon: const Text('🎵', style: TextStyle(fontSize: 18)),
        label: Text(l10n.newPoemButton),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.purple),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: ClayHeader(
                    title: l10n.poemsTitle,
                    tint: AppColors.purple,
                  ),
                ),
                // Topic chips
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    itemCount: _kTopics.length,
                    itemBuilder: (BuildContext context, int i) {
                      final bool active = _kTopics[i] == _topic;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: active,
                          label: Text(
                            '${_kTopicEmojis[i]} ${_kTopics[i]}',
                          ),
                          onSelected: (_) =>
                              setState(() => _topic = _kTopics[i]),
                          selectedColor:
                              AppColors.purple.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.purple,
                          labelStyle: theme.textTheme.titleSmall?.copyWith(
                            color: active ? AppColors.purple : AppColors.dark,
                            fontWeight:
                                active ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: active ? AppColors.purple : AppColors.grey,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: async.when(
                    loading: () => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const CircularProgressIndicator(
                            color: AppColors.purple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.contentLoading,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.dark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.purple,
                      ),
                    ),
                    data: (KidsPoem poem) => _PoemCard(poem: poem),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoemCard extends StatelessWidget {
  const _PoemCard({required this.poem});

  final KidsPoem poem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.white,
              AppColors.purple.withValues(alpha: 0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Text(poem.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              poem.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.purple,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                poem.poem,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 2.0,
                  fontStyle: FontStyle.italic,
                  color: AppColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
