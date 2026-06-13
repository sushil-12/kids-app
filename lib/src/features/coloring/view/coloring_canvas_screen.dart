import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../engine/coloring_painter.dart';
import '../view_model/coloring_view_model.dart';

/// S5 · Coloring Canvas. View layer only — all logic lives in the view-model.
class ColoringCanvasScreen extends ConsumerStatefulWidget {
  const ColoringCanvasScreen({required this.pageId, super.key});

  final String pageId;

  @override
  ConsumerState<ColoringCanvasScreen> createState() => _ColoringCanvasScreenState();
}

class _ColoringCanvasScreenState extends ConsumerState<ColoringCanvasScreen> {
  // Drives RepaintBoundary updates without rebuilding the widget tree.
  final ValueNotifier<int> _repaintTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _repaintTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CanvasState canvas = ref.watch(canvasViewModelProvider(widget.pageId));
    final CanvasViewModel vm = ref.read(canvasViewModelProvider(widget.pageId).notifier);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: Colors.white,
                    child: GestureDetector(
                      onPanStart: (DragStartDetails d) {
                        vm.startStroke(d.localPosition);
                        _repaintTick.value++;
                      },
                      onPanUpdate: (DragUpdateDetails d) {
                        vm.extendStroke(d.localPosition);
                        _repaintTick.value++;
                      },
                      onPanEnd: (_) => vm.endStroke(),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          isComplex: true,
                          willChange: true,
                          painter: ColoringPainter(
                            strokes: canvas.strokes,
                            activeStroke: canvas.activeStroke,
                            repaint: _repaintTick,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _Palette(
              selected: canvas.selectedColor,
              onSelect: vm.selectColor,
            ),
            const SizedBox(height: 12),
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
      height: 72,
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
            child: Container(
              width: 56,
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
