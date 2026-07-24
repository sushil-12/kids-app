import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';
import '../data/learn_content.dart';
import '../view_model/learn_providers.dart';

/// S· Daily Story — reads today's AI-generated moral tale.
class DailyStoryScreen extends ConsumerWidget {
  const DailyStoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<DailyStory> async = ref.watch(dailyStoryProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(storyRefreshProvider.notifier).update((int n) => n + 1);
        },
        backgroundColor: AppColors.coral,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 2.5),
        ),
        icon: const Text('✨', style: TextStyle(fontSize: 18)),
        label: Text(l10n.newStoryButton),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.coral),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ClayHeader(
                    title: l10n.dailyStoryTitle,
                    tint: AppColors.coral,
                  ),
                ),
                Expanded(
                  child: async.when(
                    loading: () => _LoadingView(message: l10n.contentLoading),
                    error: (_, __) =>
                        _LoadingView(message: l10n.contentLoading),
                    data: (DailyStory story) =>
                        _StoryView(story: story, l10n: l10n),
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

class _StoryView extends StatelessWidget {
  const _StoryView({required this.story, required this.l10n});

  final DailyStory story;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Text(story.emoji, style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 16),
          Text(
            story.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // The cinematic version of today's story — the hero experience.
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => context.push(Routes.learnStoryCinema),
            icon: const Text('🎬', style: TextStyle(fontSize: 22)),
            label: Text(
              l10n.watchStoryButton,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              story.story,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('💡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.moralLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.moral,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.dark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.coral),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
