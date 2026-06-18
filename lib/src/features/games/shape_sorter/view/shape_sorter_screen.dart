import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../../shared/shape_view.dart';
import '../view_model/shape_sorter_view_model.dart';

/// Shape Sorter (ages 2–4) — drag each tray shape onto its matching hole.
class ShapeSorterScreen extends ConsumerWidget {
  const ShapeSorterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ShapeSorterState state = ref.watch(shapeSorterProvider);

    ref.listen<bool>(
      shapeSorterProvider.select((ShapeSorterState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          celebrateWin(
            context,
            ref,
            onPlayAgain: () => ref.read(shapeSorterProvider.notifier).reset(),
          );
        }
      },
    );

    return GameScaffold(
      instruction: l10n.shapeSorterInstruction,
      progress: state.placedCount,
      total: state.total,
      accent: AppColors.coral,
      child: Column(
        children: <Widget>[
          const Spacer(),
          // Holes (drop targets).
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: <Widget>[
              for (final SortableShape hole in state.holes)
                _Hole(
                  hole: hole,
                  onAccept: () =>
                      ref.read(shapeSorterProvider.notifier).place(hole.kind),
                ),
            ],
          ),
          const Spacer(),
          // Tray (draggable shapes).
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: <Widget>[
                for (final ShapeKind kind in state.tray)
                  _TrayShape(
                    kind: kind,
                    color: _colorFor(state, kind),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _colorFor(ShapeSorterState state, ShapeKind kind) =>
      state.holes.firstWhere((SortableShape s) => s.kind == kind).color;
}

class _Hole extends StatelessWidget {
  const _Hole({required this.hole, required this.onAccept});

  final SortableShape hole;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    if (hole.placed) {
      return ShapeView(kind: hole.kind, color: hole.color, size: 84);
    }
    return DragTarget<ShapeKind>(
      onWillAcceptWithDetails: (DragTargetDetails<ShapeKind> d) => d.data == hole.kind,
      onAcceptWithDetails: (_) => onAccept(),
      builder: (BuildContext context, List<ShapeKind?> candidate, _) {
        final bool hovering = candidate.isNotEmpty;
        return AnimatedScale(
          scale: hovering ? 1.15 : 1,
          duration: const Duration(milliseconds: 150),
          child: ShapeView(kind: hole.kind, color: hole.color, size: 84, outlined: true),
        );
      },
    );
  }
}

class _TrayShape extends StatelessWidget {
  const _TrayShape({required this.kind, required this.color});

  final ShapeKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ShapeView shape = ShapeView(kind: kind, color: color, size: 72);
    return Draggable<ShapeKind>(
      data: kind,
      feedback: ShapeView(kind: kind, color: color, size: 88),
      childWhenDragging: Opacity(opacity: 0.25, child: shape),
      child: shape,
    );
  }
}
