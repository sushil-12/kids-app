import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../data/coloring_template.dart';
import '../engine/coloring_painter.dart';
import '../view_model/coloring_view_model.dart';

/// S5 · Coloring Canvas. Tap-to-fill is the hero interaction; brush + eraser
/// are secondary. All logic lives in [CanvasViewModel] — this is view-only.
class ColoringCanvasScreen extends ConsumerStatefulWidget {
  const ColoringCanvasScreen({required this.pageId, super.key});

  final String pageId;

  @override
  ConsumerState<ColoringCanvasScreen> createState() => _ColoringCanvasScreenState();
}

class _ColoringCanvasScreenState extends ConsumerState<ColoringCanvasScreen> {
  // Repaints the canvas during a brush drag without rebuilding the tree.
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String id = widget.pageId;
    final CanvasState state = ref.watch(canvasViewModelProvider(id));
    final CanvasViewModel vm = ref.read(canvasViewModelProvider(id).notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(title: state.template.title),
            Expanded(child: _Canvas(state: state, vm: vm, tick: _tick)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.pickAColor,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
              ),
            ),
            _ToolBar(state: state, vm: vm),
            const SizedBox(height: 10),
            _Palette(selected: state.selectedColor, onSelect: vm.selectColor),
            const SizedBox(height: 8),
            _DoneButton(
              label: l10n.doneButton,
              onDone: () => _celebrate(context, state.template.stickerRewardId),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _celebrate(BuildContext context, String stickerRewardId) {
    // Finishing a picture earns its themed, persisted sticker (CLAUDE.md §6).
    // awardById falls back to a random sticker if the id is ever unknown.
    final StickerAward award =
        ref.read(rewardsProvider.notifier).awardById(stickerRewardId);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final AppLocalizations l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: AppColors.purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(award.sticker.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(
                l10n.celebrationTitle,
                style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                award.isNew ? l10n.newStickerEarned : l10n.allStickersEarned,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: AppColors.cream),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.yellow),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.colorAgain,
                style: const TextStyle(color: AppColors.dark),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: <Widget>[
          IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.state, required this.vm, required this.tick});

  final CanvasState state;
  final CanvasViewModel vm;
  final ValueNotifier<int> tick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Size size = constraints.biggest;
              final CanvasFit fit = CanvasFit.of(size, state.template.viewBox);

              void handleTap(Offset local) => vm.tapAt(fit.toLogical(local));

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (TapUpDetails d) => handleTap(d.localPosition),
                onPanStart: (DragStartDetails d) {
                  vm.startStroke(fit.toLogical(d.localPosition));
                  tick.value++;
                },
                onPanUpdate: (DragUpdateDetails d) {
                  vm.extendStroke(fit.toLogical(d.localPosition));
                  tick.value++;
                },
                onPanEnd: (_) => vm.endStroke(),
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    size: Size.infinite,
                    painter: ColoringPainter(
                      template: state.template,
                      fills: state.fills,
                      strokes: state.strokes,
                      activeStroke: state.activeStroke,
                      repaint: tick,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({required this.state, required this.vm});

  final CanvasState state;
  final CanvasViewModel vm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _ToolButton(
          icon: Icons.format_color_fill_rounded,
          label: l10n.toolFill,
          color: AppColors.teal,
          selected: state.tool == CanvasTool.fill,
          onTap: () => vm.selectTool(CanvasTool.fill),
        ),
        _ToolButton(
          icon: Icons.brush_rounded,
          label: l10n.toolBrush,
          color: AppColors.coral,
          selected: state.tool == CanvasTool.brush,
          onTap: () => vm.selectTool(CanvasTool.brush),
        ),
        _ToolButton(
          icon: Icons.cleaning_services_rounded,
          label: l10n.toolErase,
          color: AppColors.purple,
          selected: state.tool == CanvasTool.eraser,
          onTap: () => vm.selectTool(CanvasTool.eraser),
        ),
        _ToolButton(
          icon: Icons.undo_rounded,
          label: l10n.toolUndo,
          color: AppColors.blue,
          selected: false,
          enabled: state.canUndo,
          onTap: vm.undo,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? color : color.withValues(alpha: 0.15);
    final Color fg = selected ? Colors.white : color;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 30),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({required this.selected, required this.onSelect});

  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: AppColors.crayonPalette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int i) {
          final Color color = AppColors.crayonPalette[i];
          final bool isSelected = color == selected;
          return GestureDetector(
            onTap: () => onSelect(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isSelected ? 56 : 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.dark : AppColors.grey,
                  width: isSelected ? 4 : 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label, required this.onDone});

  final String label;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          minimumSize: const Size.fromHeight(60),
        ),
        onPressed: onDone,
        icon: const Icon(Icons.check_rounded),
        label: Text(label),
      ),
    );
  }
}
