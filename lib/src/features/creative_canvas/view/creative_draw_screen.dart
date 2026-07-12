import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../coloring/data/coloring_template.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../data/creative_artwork.dart';
import '../data/creative_guide.dart';
import '../engine/creative_painter.dart';
import '../view_model/creative_canvas_view_model.dart';
import '../view_model/my_art_view_model.dart';

/// The Creative Canvas drawing surface. Free-draw on a blank page, or trace a
/// faint guide. All logic lives in [CreativeCanvasViewModel] — this is
/// view-only. Finishing snapshots the canvas to the saved-art gallery and
/// earns a sticker.
class CreativeDrawScreen extends ConsumerStatefulWidget {
  const CreativeDrawScreen({required this.guideId, super.key});

  final String guideId;

  @override
  ConsumerState<CreativeDrawScreen> createState() => _CreativeDrawScreenState();
}

class _CreativeDrawScreenState extends ConsumerState<CreativeDrawScreen> {
  // Repaints the canvas during a brush drag without rebuilding the tree.
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  // Captures the painted canvas to a PNG when the child taps Done.
  final GlobalKey _captureKey = GlobalKey();

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String id = widget.guideId;
    final CreativeState state = ref.watch(creativeCanvasViewModelProvider(id));
    final CreativeCanvasViewModel vm =
        ref.read(creativeCanvasViewModelProvider(id).notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(title: _title(l10n, state.guide)),
            Expanded(
              child: _Canvas(
                state: state,
                vm: vm,
                tick: _tick,
                captureKey: _captureKey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                state.mode == CreativeMode.freeDraw
                    ? l10n.pickAColor
                    : l10n.creativeTrace,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
              ),
            ),
            _ToolBar(state: state, vm: vm),
            const SizedBox(height: 8),
            _BrushSizePicker(selected: state.brush, onSelect: vm.selectBrush),
            const SizedBox(height: 8),
            _Palette(selected: state.selectedColor, onSelect: vm.selectColor),
            const SizedBox(height: 8),
            _DoneButton(
              label: l10n.doneButton,
              enabled: state.hasDrawn,
              onDone: () => _finish(context, state, vm),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n, TraceGuide? guide) {
    if (guide == null) return l10n.creativeFreeDraw;
    return _guideTitle(l10n, guide);
  }

  /// Saves a PNG snapshot of the drawing, awards a sticker, and celebrates.
  Future<void> _finish(
    BuildContext context,
    CreativeState state,
    CreativeCanvasViewModel vm,
  ) async {
    final String? png = await _capturePng();
    if (png != null) {
      ref.read(myArtProvider.notifier).add(
            CreativeArtwork(
              id: 'art_${DateTime.now().microsecondsSinceEpoch}',
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
              pngBase64: png,
            ),
          );
    }
    final StickerAward award = ref
        .read(rewardsProvider.notifier)
        .awardById(state.guide?.stickerRewardId ?? 'palette');
    if (!context.mounted) return;
    _celebrate(context, award, vm);
  }

  /// Renders the [RepaintBoundary] under [_captureKey] to a base64 PNG.
  Future<String?> _capturePng() async {
    try {
      final RenderObject? object =
          _captureKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return null;
      final ui.Image image = await object.toImage(pixelRatio: 3);
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return null;
      return base64Encode(bytes.buffer.asUint8List());
    } catch (_) {
      // Never block the celebration on a capture failure.
      return null;
    }
  }

  void _celebrate(
    BuildContext context,
    StickerAward award,
    CreativeCanvasViewModel vm,
  ) {
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
                style: Theme.of(ctx)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                award.isNew ? l10n.newStickerEarned : l10n.allStickersEarned,
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.cream),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: Text(
                l10n.creativeMyArt,
                style: const TextStyle(color: AppColors.cream),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.yellow),
              onPressed: () {
                vm.clear();
                Navigator.of(ctx).pop();
              },
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

/// Resolves a guide's localized title from its [TraceGuide.titleKey].
String _guideTitle(AppLocalizations l10n, TraceGuide guide) {
  return switch (guide.titleKey) {
    'shape_circle' => l10n.shapeCircle,
    'shape_square' => l10n.shapeSquare,
    'shape_triangle' => l10n.shapeTriangle,
    'shape_star' => l10n.shapeStar,
    'shape_heart' => l10n.shapeHeart,
    'fruitApple' => l10n.fruitApple,
    'fruitBanana' => l10n.fruitBanana,
    'fruitPear' => l10n.fruitPear,
    'fruitGrapes' => l10n.fruitGrapes,
    _ => guide.emoji,
  };
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.state,
    required this.vm,
    required this.tick,
    required this.captureKey,
  });

  final CreativeState state;
  final CreativeCanvasViewModel vm;
  final ValueNotifier<int> tick;
  final GlobalKey captureKey;

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
              final CanvasFit fit = CanvasFit.of(size, state.viewBox);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                  key: captureKey,
                  child: ColoredBox(
                    color: Colors.white,
                    child: CustomPaint(
                      isComplex: true,
                      willChange: true,
                      size: Size.infinite,
                      painter: CreativePainter(
                        viewBox: state.viewBox,
                        guidePaths: state.guidePaths,
                        strokes: state.strokes,
                        activeStroke: state.activeStroke,
                        repaint: tick,
                      ),
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

  final CreativeState state;
  final CreativeCanvasViewModel vm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _ToolButton(
          icon: Icons.brush_rounded,
          label: l10n.toolBrush,
          color: AppColors.coral,
          selected: state.tool == CreativeTool.brush,
          onTap: () => vm.selectTool(CreativeTool.brush),
        ),
        _ToolButton(
          icon: Icons.cleaning_services_rounded,
          label: l10n.toolErase,
          color: AppColors.purple,
          selected: state.tool == CreativeTool.eraser,
          onTap: () => vm.selectTool(CreativeTool.eraser),
        ),
        _ToolButton(
          icon: Icons.undo_rounded,
          label: l10n.toolUndo,
          color: AppColors.blue,
          selected: false,
          enabled: state.canUndo,
          onTap: vm.undo,
        ),
        _ToolButton(
          icon: Icons.delete_outline_rounded,
          label: l10n.toolClear,
          color: AppColors.teal,
          selected: false,
          enabled: state.hasDrawn,
          onTap: vm.clear,
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 28),
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

/// Three dots that pick the brush thickness.
class _BrushSizePicker extends StatelessWidget {
  const _BrushSizePicker({required this.selected, required this.onSelect});

  final CreativeBrush selected;
  final ValueChanged<CreativeBrush> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final CreativeBrush brush in CreativeBrush.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GestureDetector(
              onTap: () => onSelect(brush),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey,
                  border: Border.all(
                    color: brush == selected ? AppColors.dark : AppColors.grey,
                    width: brush == selected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 6 + brush.width * 1.6,
                    height: 6 + brush.width * 1.6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
  const _DoneButton({
    required this.label,
    required this.enabled,
    required this.onDone,
  });

  final String label;
  final bool enabled;
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
        onPressed: enabled ? onDone : null,
        icon: const Icon(Icons.check_rounded),
        label: Text(label),
      ),
    );
  }
}
