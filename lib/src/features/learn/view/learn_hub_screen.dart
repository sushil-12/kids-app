import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../core/widgets/clay_icons.dart';
import '../../../l10n/app_localizations.dart';

/// S· Learn Hub — entry point to Stories, ABC, and Poems, in the pastel-clay
/// design language (green tint, matching the Home "Learn" tile).
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.green),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: <Widget>[
                ClayHeader(title: l10n.learnHubTitle, tint: AppColors.green),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(l10n.learnHubSubtitle, style: clayBody()),
                ),
                const SizedBox(height: 20),
                _LearnCard(
                  glyph: ClayIconKind.storybook,
                  title: l10n.dailyStoryTitle,
                  subtitle: l10n.dailyStorySubtitle,
                  color: AppColors.coral,
                  onTap: () => context.push(Routes.learnStory),
                ),
                const SizedBox(height: 16),
                _LearnCard(
                  glyph: ClayIconKind.abc,
                  title: l10n.abcTitle,
                  subtitle: l10n.abcSubtitle,
                  color: AppColors.teal,
                  onTap: () => context.push(Routes.learnAbc),
                ),
                const SizedBox(height: 16),
                _LearnCard(
                  glyph: ClayIconKind.music,
                  title: l10n.poemsTitle,
                  subtitle: l10n.poemsSubtitle,
                  color: AppColors.purple,
                  onTap: () => context.push(Routes.learnPoems),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final ClayIconKind glyph;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          ClayIcon(kind: glyph, tint: color, size: 64),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: clayTitle(fontSize: 19)),
                const SizedBox(height: 2),
                Text(subtitle, style: clayBody(fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 28),
        ],
      ),
    );
  }
}
