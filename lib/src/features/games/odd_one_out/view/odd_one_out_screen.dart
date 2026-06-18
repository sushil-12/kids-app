import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../../shared/shape_view.dart';
import '../data/odd_item.dart';
import '../view_model/odd_one_out_view_model.dart';

/// Odd-One-Out — "Which one is different?" (ages 2–4). A grid shows several
/// matching shapes and one that stands out; the child taps the different one,
/// across five gently growing rounds.
class OddOneOutScreen extends ConsumerWidget {
  const OddOneOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final OddOneOutState state = ref.watch(oddOneOutProvider);
    final OddOneOutViewModel vm = ref.read(oddOneOutProvider.notifier);

    // Finding the odd tile solves the round; pause so the highlight is seen,
    // then move on (or finish).
    ref.listen<bool>(
      oddOneOutProvider.select((OddOneOutState s) => s.solved),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (context.mounted) vm.nextRound();
          });
        }
      },
    );

    ref.listen<bool>(
      oddOneOutProvider.select((OddOneOutState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    final int crossAxisCount = state.tiles.length <= 4 ? 2 : 3;

    return GameScaffold(
      instruction: l10n.oddOneOutInstruction,
      progress: state.roundsDone,
      total: OddOneOutState.totalRounds,
      accent: AppColors.pink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: state.tiles.length,
            itemBuilder: (BuildContext context, int i) => _OddTile(
              item: state.tiles[i],
              isOdd: i == state.oddIndex,
              found: state.solved,
              onCorrect: () => vm.choose(i),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single grid tile. The odd one calls [onCorrect]; matching tiles wobble on
/// tap (no fail state). Once [found], the odd tile glows so the child sees what
/// they spotted before the next round.
class _OddTile extends StatefulWidget {
  const _OddTile({
    required this.item,
    required this.isOdd,
    required this.found,
    required this.onCorrect,
  });

  final OddItem item;
  final bool isOdd;
  final bool found;
  final VoidCallback onCorrect;

  @override
  State<_OddTile> createState() => _OddTileState();
}

class _OddTileState extends State<_OddTile> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.found) return;
    if (widget.isOdd) {
      widget.onCorrect();
    } else {
      _wobble.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool highlight = widget.found && widget.isOdd;
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (BuildContext context, Widget? child) {
          // A small left-right shimmy that decays — gentle, never alarming.
          final double dx =
              math.sin(_wobble.value * math.pi * 4) * 8 * (1 - _wobble.value);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: highlight
                ? Border.all(color: AppColors.yellow, width: 4)
                : null,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (highlight ? AppColors.yellow : widget.item.color)
                    .withValues(alpha: highlight ? 0.5 : 0.2),
                blurRadius: highlight ? 20 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: ShapeView(
              kind: widget.item.kind,
              color: widget.item.color,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
