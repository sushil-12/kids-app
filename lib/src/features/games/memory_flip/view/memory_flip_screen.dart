import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../view_model/memory_flip_view_model.dart';

/// Memory Flip (ages 2–6) — flip cards to find matching pairs.
class MemoryFlipScreen extends ConsumerWidget {
  const MemoryFlipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MemoryFlipState state = ref.watch(memoryFlipProvider);
    final MemoryFlipViewModel vm = ref.read(memoryFlipProvider.notifier);

    // After a wrong guess, pause so the child can see both, then flip back.
    ref.listen<bool>(
      memoryFlipProvider.select((MemoryFlipState s) => s.busy),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (context.mounted) vm.hideMismatch();
          });
        }
      },
    );

    ref.listen<bool>(
      memoryFlipProvider.select((MemoryFlipState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    return GameScaffold(
      instruction: l10n.memoryFlipInstruction,
      progress: state.matchedPairs,
      total: state.totalPairs,
      accent: AppColors.purple,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.cards.length,
            itemBuilder: (BuildContext context, int i) => _Card(
              card: state.cards[i],
              onTap: () => vm.flip(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.card, required this.onTap});

  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool shown = card.faceUp || card.matched;
    return GestureDetector(
      onTap: shown ? null : onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> anim) {
          final Animation<double> rotate = Tween<double>(begin: math.pi, end: 0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (BuildContext context, Widget? child) {
              final bool mirrored = rotate.value.abs() > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotate.value),
                child: mirrored ? const SizedBox.shrink() : child,
              );
            },
          );
        },
        child: shown
            ? _Face(
                key: const ValueKey<bool>(true),
                color: card.matched ? AppColors.green : Colors.white,
                child: Text(card.symbol, style: const TextStyle(fontSize: 56)),
              )
            : const _Face(
                key: ValueKey<bool>(false),
                color: AppColors.purple,
                child: Icon(Icons.question_mark_rounded, color: Colors.white, size: 48),
              ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
