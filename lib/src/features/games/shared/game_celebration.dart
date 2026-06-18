import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/buddy.dart';
import '../../profile/view_model/profile_view_model.dart';

/// Shared win overlay for every game. There are no fail states (House Rule §5)
/// so this is the only end screen — it always celebrates.
///
/// The child's chosen buddy appears here clapping for them, so every win feels
/// personal. When a sticker is earned, pass its [stickerEmoji] so the child
/// sees exactly what they won; [isNewSticker] controls the subtitle (a
/// brand-new sticker vs. a collection that is already full). With no emoji it
/// shows a generic 🎉.
///
/// [onPlayAgain] should call the game view-model's `reset()`. "More games" pops
/// back to the hub.
Future<void> showGameCelebration(
  BuildContext context, {
  required VoidCallback onPlayAgain,
  String? stickerEmoji,
  bool isNewSticker = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      final AppLocalizations l10n = AppLocalizations.of(ctx);
      return AlertDialog(
        backgroundColor: AppColors.purple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _ClappingBuddy(),
            const SizedBox(height: 8),
            Text(stickerEmoji ?? '🎉', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              l10n.gameWinTitle,
              style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              stickerEmoji == null || isNewSticker
                  ? l10n.newStickerEarned
                  : l10n.allStickersEarned,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.cream),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctx.pop();
            },
            child: Text(
              l10n.backToGames,
              style: const TextStyle(color: AppColors.cream),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.yellow),
            onPressed: () {
              Navigator.of(ctx).pop();
              onPlayAgain();
            },
            child: Text(
              l10n.playAgain,
              style: const TextStyle(color: AppColors.dark),
            ),
          ),
        ],
      );
    },
  );
}

/// The child's buddy cheering them on with clapping hands and a happy bob. Reads
/// the chosen buddy from [buddyProvider] so it personalizes automatically.
class _ClappingBuddy extends ConsumerStatefulWidget {
  const _ClappingBuddy();

  @override
  ConsumerState<_ClappingBuddy> createState() => _ClappingBuddyState();
}

class _ClappingBuddyState extends ConsumerState<_ClappingBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Buddy buddy = ref.watch(buddyProvider);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          // Hands swing in toward the buddy; the buddy bobs up a little.
          final double t = _controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Transform.translate(
                offset: Offset(8 * t, 0),
                child: const Text('👏', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: Offset(0, -6 * t),
                child: Text(buddy.emoji, style: const TextStyle(fontSize: 52)),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: Offset(-8 * t, 0),
                child: Transform.flip(
                  flipX: true,
                  child: const Text('👏', style: TextStyle(fontSize: 28)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
