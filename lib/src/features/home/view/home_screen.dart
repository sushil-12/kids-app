import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// S3 · Home (Kid Hub).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const CircleAvatar(radius: 28, backgroundColor: AppColors.yellow),
                  const SizedBox(width: 12),
                  Text(l10n.homeGreeting('Maya'),
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => _parentGate(context, Routes.settings),
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _BigTile(
                  label: l10n.tileColor,
                  subtitle: l10n.tileColorSubtitle(60),
                  color: AppColors.coral,
                  icon: Icons.brush,
                  onTap: () => context.push(Routes.gallery),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigTile(
                  label: l10n.tilePlay,
                  subtitle: l10n.tilePlaySubtitle(5),
                  color: AppColors.purple,
                  icon: Icons.extension,
                  onTap: () => context.push(Routes.games),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.dark,
                  minimumSize: const Size.fromHeight(72),
                ),
                onPressed: () => context.push(Routes.stickers),
                icon: const Text('⭐', style: TextStyle(fontSize: 24)),
                label: Text(l10n.stickerRoom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _parentGate(BuildContext context, String destination) {
    // Real parent gate is a math-question modal; routed here for the walkthrough.
    context.push(destination);
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(icon, size: 36, color: color),
              ),
              const Spacer(),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white)),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
