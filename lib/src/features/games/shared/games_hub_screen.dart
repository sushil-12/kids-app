import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../core/widgets/clay_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/child_profile.dart';
import '../../profile/view_model/profile_view_model.dart';
import 'games_catalog.dart';

/// S7 · Games Hub, in the pastel-clay design language (purple tint). Lists the
/// brain games grouped by age band, with the child's own band shown first
/// (driven by their saved profile).
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AgeBand? ageBand = ref.watch(profileProvider)?.ageBand;
    // The child's band leads; the other follows so all content stays reachable.
    final bool seniorFirst = ageBand == AgeBand.senior;
    final _BandSection junior =
        _BandSection(label: l10n.ageBand24, band: GameBand.junior);
    final _BandSection senior =
        _BandSection(label: l10n.ageBand56, band: GameBand.senior);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ClayBackground(tint: AppColors.purple),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: <Widget>[
                ClayHeader(title: l10n.gamesTitle, tint: AppColors.purple),
                const SizedBox(height: 20),
                if (seniorFirst) senior else junior,
                const SizedBox(height: 24),
                if (seniorFirst) junior else senior,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandSection extends StatelessWidget {
  const _BandSection({required this.label, required this.band});

  final String label;
  final GameBand band;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<GameInfo> games =
        kGames.where((GameInfo g) => g.band == band).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(label, style: clayTitle(fontSize: 17)),
        ),
        for (final GameInfo game in games)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _GameCard(game: game, title: game.title(l10n)),
          ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.title});

  final GameInfo game;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ClayTile(
      color: game.color,
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(game.route),
      child: Row(
        children: <Widget>[
          ClayIcon(kind: game.glyph, tint: game.color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: clayTitle(fontSize: 18)),
          ),
          Icon(Icons.play_circle_fill, size: 36, color: game.color),
        ],
      ),
    );
  }
}
