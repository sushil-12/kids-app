import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../games/shared/game_celebration.dart';
import '../view_model/rewards_view_model.dart';

/// Awards a sticker for finishing an activity, then shows the shared win
/// celebration displaying exactly what was earned. This is the single entry
/// point games use so awarding and celebrating never drift apart.
///
/// [onPlayAgain] is forwarded to the celebration (the game's `reset()`).
Future<void> celebrateWin(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onPlayAgain,
}) {
  final StickerAward award = ref.read(rewardsProvider.notifier).awardRandom();
  return showGameCelebration(
    context,
    onPlayAgain: onPlayAgain,
    stickerEmoji: award.sticker.emoji,
    isNewSticker: award.isNew,
  );
}
