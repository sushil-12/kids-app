import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/data/sticker.dart';
import '../../rewards/data/sticker_catalog.dart';
import '../../rewards/view_model/rewards_view_model.dart';

/// S9 · My Sticker Room. Shows the whole sticker catalog: earned stickers are
/// bright and full-color, ones still to find are soft, greyed placeholders so
/// children can see what's left to collect.
class StickerRoomScreen extends ConsumerWidget {
  const StickerRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RewardsState rewards = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stickerRoom)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: _ProgressHeader(earned: rewards.earned, total: rewards.total),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: kStickers.length,
              itemBuilder: (BuildContext context, int i) {
                final Sticker sticker = kStickers[i];
                return _StickerSlot(
                  sticker: sticker,
                  earned: rewards.contains(sticker.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "{earned} of {total} stickers collected!" with a progress bar.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double fraction = total == 0 ? 0 : (earned / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.stickersCollected(earned, total),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            backgroundColor: AppColors.grey,
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

/// One sticker cell. Earned cells pop in full color; locked cells show a faded
/// glyph behind a soft lock so the goal stays visible but unmistakably "to do".
class _StickerSlot extends StatelessWidget {
  const _StickerSlot({required this.sticker, required this.earned});

  final Sticker sticker;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: earned ? Colors.white : AppColors.grey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: earned
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.yellow.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: earned
          ? Text(sticker.emoji, style: const TextStyle(fontSize: 36))
          : Opacity(
              opacity: 0.35,
              child: Text(sticker.emoji, style: const TextStyle(fontSize: 32)),
            ),
    );
  }
}
