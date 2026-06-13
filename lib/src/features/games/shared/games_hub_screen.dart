import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// S7 · Games Hub.
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> games = <String>[
      l10n.gameShapeSorter,
      l10n.gameColorMatch,
      l10n.gameMemoryFlip,
      l10n.gameLetterTrace,
      l10n.gameCountTap,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gamesTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int i) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(games[i], style: Theme.of(context).textTheme.titleLarge),
            trailing: const Icon(Icons.play_circle_fill, size: 36),
          ),
        ),
      ),
    );
  }
}
