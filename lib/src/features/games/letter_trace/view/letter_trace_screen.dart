import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../view_model/letter_trace_view_model.dart';

/// Letter Trace (ages 5–6) — sweep a finger through the guide dots of a letter.
class LetterTraceScreen extends ConsumerWidget {
  const LetterTraceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LetterTraceState state = ref.watch(letterTraceProvider);
    final LetterTraceViewModel vm = ref.read(letterTraceProvider.notifier);

    ref.listen<bool>(
      letterTraceProvider.select((LetterTraceState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(context, ref, onPlayAgain: vm.reset);
        }
      },
    );

    return GameScaffold(
      instruction: l10n.letterTraceInstruction(state.letter),
      progress: state.progress,
      total: state.total,
      accent: AppColors.blue,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size size = constraints.biggest;

                void handle(Offset local) => vm.touch(
                      Offset(local.dx / size.width, local.dy / size.height),
                    );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails d) => handle(d.localPosition),
                  onPanUpdate: (DragUpdateDetails d) => handle(d.localPosition),
                  onTapDown: (TapDownDetails d) => handle(d.localPosition),
                  child: Stack(
                    children: <Widget>[
                      // Faint guide glyph behind the dots.
                      Center(
                        child: Text(
                          state.letter,
                          style: TextStyle(
                            fontSize: size.shortestSide * 0.85,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue.withValues(alpha: 0.12),
                            height: 1,
                          ),
                        ),
                      ),
                      for (int i = 0; i < state.dots.length; i++)
                        _Dot(
                          center: Offset(
                            state.dots[i].dx * size.width,
                            state.dots[i].dy * size.height,
                          ),
                          lit: state.visited.contains(i),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.center, required this.lit});

  final Offset center;
  final bool lit;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - _size / 2,
      top: center.dy - _size / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: lit ? AppColors.green : AppColors.blue.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(
            color: lit ? AppColors.green : AppColors.blue,
            width: 3,
          ),
        ),
        child: lit
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
