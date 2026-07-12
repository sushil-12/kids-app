import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// S· Learn Hub — entry point to Stories, ABC, and Poems.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(l10n.learnHubTitle, style: theme.textTheme.headlineMedium),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            Text(
              l10n.learnHubSubtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _LearnCard(
              emoji: '📖',
              title: l10n.dailyStoryTitle,
              subtitle: l10n.dailyStorySubtitle,
              color: AppColors.coral,
              onTap: () => context.push(Routes.learnStory),
            ),
            const SizedBox(height: 16),
            _LearnCard(
              emoji: '🔤',
              title: l10n.abcTitle,
              subtitle: l10n.abcSubtitle,
              color: AppColors.teal,
              onTap: () => context.push(Routes.learnAbc),
            ),
            const SizedBox(height: 16),
            _LearnCard(
              emoji: '🎵',
              title: l10n.poemsTitle,
              subtitle: l10n.poemsSubtitle,
              color: AppColors.purple,
              onTap: () => context.push(Routes.learnPoems),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
