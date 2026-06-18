import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../view_model/color_match_view_model.dart';

/// Color Match (ages 2–4) — "Tap everything {color}!" across three rounds.
class ColorMatchScreen extends ConsumerWidget {
  const ColorMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorMatchState state = ref.watch(colorMatchProvider);
    final ColorMatchViewModel vm = ref.read(colorMatchProvider.notifier);

    // When a round's matches are all found, pause then advance / finish.
    ref.listen<bool>(
      colorMatchProvider.select((ColorMatchState s) => s.roundComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          Future<void>.delayed(const Duration(milliseconds: 700), () {
            if (context.mounted) vm.nextRound();
          });
        }
      },
    );

    ref.listen<bool>(
      colorMatchProvider.select((ColorMatchState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    return GameScaffold(
      instruction: l10n.colorMatchInstruction(state.target.label(l10n)),
      progress: state.roundsDone,
      total: ColorMatchState.totalRounds,
      accent: AppColors.teal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: state.items.length,
          itemBuilder: (BuildContext context, int i) {
            final MatchColor item = state.items[i];
            final bool isMatch = item == state.target;
            return _ColorTile(
              key: ValueKey<int>(state.round * 100 + i),
              color: item.color,
              found: state.found.contains(i),
              onCorrectTap: isMatch ? () => vm.tapMatch(i) : null,
            );
          },
        ),
      ),
    );
  }
}

/// A tappable color circle. A correct tap reports up; a wrong tap wobbles in
/// place (no penalty, House Rule §5).
class _ColorTile extends StatefulWidget {
  const _ColorTile({
    required this.color,
    required this.found,
    required this.onCorrectTap,
    super.key,
  });

  final Color color;
  final bool found;
  final VoidCallback? onCorrectTap;

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onCorrectTap != null) {
      widget.onCorrectTap!();
    } else {
      _wobble.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.found ? null : _onTap,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (BuildContext context, Widget? child) {
          // A quick left-right shimmy that decays to zero.
          final double dx =
              math.sin(_wobble.value * math.pi * 3) * 9 * (1 - _wobble.value);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: AnimatedScale(
          scale: widget.found ? 0.85 : 1,
          duration: const Duration(milliseconds: 200),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.found
                ? const Center(
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
