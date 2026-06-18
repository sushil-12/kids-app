import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../../shared/shape_view.dart';
import '../data/pattern_element.dart';
import '../view_model/pattern_view_model.dart';

/// Pattern Sequence — "What's Next?" (ages 5–6). The child reads a repeating
/// run of colored shapes and taps the one that comes next, across five rounds.
class PatternScreen extends ConsumerWidget {
  const PatternScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PatternState state = ref.watch(patternProvider);
    final PatternViewModel vm = ref.read(patternProvider.notifier);

    // A correct pick solves the round; pause briefly so the slotted-in shape is
    // visible, then move on (or finish).
    ref.listen<bool>(
      patternProvider.select((PatternState s) => s.solved),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (context.mounted) vm.nextRound();
          });
        }
      },
    );

    ref.listen<bool>(
      patternProvider.select((PatternState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    return GameScaffold(
      instruction: l10n.patternInstruction,
      progress: state.roundsDone,
      total: PatternState.totalRounds,
      accent: AppColors.green,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _Sequence(state: state),
          _Options(
            state: state,
            onCorrect: () => vm.choose(state.answerIndex),
          ),
        ],
      ),
    );
  }
}

/// The visible run of shapes followed by the puzzle slot. Once [PatternState.solved]
/// the slot reveals the answer with a gentle pop.
class _Sequence extends StatelessWidget {
  const _Sequence({required this.state});

  final PatternState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FittedBox(
        child: Row(
          children: <Widget>[
            for (final PatternElement e in state.sequence)
              Padding(
                padding: const EdgeInsets.all(6),
                child: ShapeView(kind: e.kind, color: e.color, size: 60),
              ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: _PuzzleSlot(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "?" target. Empty (a dashed-feeling outline + "?") until solved, then it
/// scales the answer shape into place.
class _PuzzleSlot extends StatelessWidget {
  const _PuzzleSlot({required this.state});

  final PatternState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> anim) =>
          ScaleTransition(scale: anim, child: child),
      child: state.solved
          ? ShapeView(
              key: const ValueKey<String>('answer'),
              kind: state.answer.kind,
              color: state.answer.color,
              size: 60,
            )
          : Container(
              key: const ValueKey<String>('slot'),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
    );
  }
}

/// The three choice tiles. The correct one calls [onCorrect]; wrong ones wobble
/// in place (no fail state). Choices lock once the round is solved.
class _Options extends StatelessWidget {
  const _Options({required this.state, required this.onCorrect});

  final PatternState state;
  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (int i = 0; i < state.options.length; i++)
          _OptionTile(
            element: state.options[i],
            isCorrect: i == state.answerIndex,
            locked: state.solved,
            onCorrect: onCorrect,
          ),
      ],
    );
  }
}

/// A single tappable choice. Knows whether it is the right answer so it can give
/// instant local feedback — a correct tap bubbles up, a wrong tap shakes gently.
class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.element,
    required this.isCorrect,
    required this.locked,
    required this.onCorrect,
  });

  final PatternElement element;
  final bool isCorrect;
  final bool locked;
  final VoidCallback onCorrect;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
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
    if (widget.locked) return;
    if (widget.isCorrect) {
      widget.onCorrect();
    } else {
      _wobble.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.element.color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ShapeView(
            kind: widget.element.kind,
            color: widget.element.color,
            size: 72,
          ),
        ),
      ),
    );
  }
}
