import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../view_model/count_tap_view_model.dart';

/// Count & Tap (ages 5–6) — "Tap {count} apples!" across five rounds.
class CountTapScreen extends ConsumerWidget {
  const CountTapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CountTapState state = ref.watch(countTapProvider);
    final CountTapViewModel vm = ref.read(countTapProvider.notifier);

    ref.listen<bool>(
      countTapProvider.select((CountTapState s) => s.roundComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          Future<void>.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) vm.nextRound();
          });
        }
      },
    );

    ref.listen<bool>(
      countTapProvider.select((CountTapState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    return GameScaffold(
      instruction: l10n.countTapInstruction(state.target),
      progress: state.roundsDone,
      total: CountTapState.totalRounds,
      accent: AppColors.orange,
      child: Column(
        children: <Widget>[
          _Counter(tapped: state.tapped.length, target: state.target),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: state.itemCount,
                itemBuilder: (BuildContext context, int i) => _Apple(
                  picked: state.tapped.contains(i),
                  onTap: () => vm.tapItem(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.tapped, required this.target});

  final int tapped;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$tapped / $target',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.orange,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _Apple extends StatelessWidget {
  const _Apple({required this.picked, required this.onTap});

  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: picked ? null : onTap,
      child: AnimatedScale(
        scale: picked ? 0.8 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: picked ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: const FittedBox(
            child: Text('🍎', style: TextStyle(fontSize: 64)),
          ),
        ),
      ),
    );
  }
}
