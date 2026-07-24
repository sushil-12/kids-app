import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';
import '../../../l10n/app_localizations.dart';
import '../../games/shared/game_celebration.dart';
import '../../rewards/view_model/rewards_view_model.dart';
import '../data/by_number_palette.dart';
import '../data/coloring_template.dart';
import '../engine/color_by_number_painter.dart';
import '../view_model/color_by_number_view_model.dart';

/// S5b · Color-by-Number. A guided coloring variation: pick a number, tap the
/// regions marked with it, and the picture fills itself in the right colors.
/// No fail state — a tap with the wrong number just nudges.
class ColorByNumberScreen extends ConsumerStatefulWidget {
  const ColorByNumberScreen({required this.pageId, super.key});

  final String pageId;

  @override
  ConsumerState<ColorByNumberScreen> createState() =>
      _ColorByNumberScreenState();
}

class _ColorByNumberScreenState extends ConsumerState<ColorByNumberScreen>
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String id = widget.pageId;
    final ByNumberState state = ref.watch(byNumberProvider(id));
    final ByNumberViewModel vm = ref.read(byNumberProvider(id).notifier);

    // A mismatched tap bumps wrongNudge → play a gentle shake.
    ref.listen<int>(
      byNumberProvider(id).select((ByNumberState s) => s.wrongNudge),
      (int? was, int now) {
        if (was != null && now > was) _wobble.forward(from: 0);
      },
    );

    // Finishing awards the picture's themed, persisted sticker.
    ref.listen<bool>(
      byNumberProvider(id).select((ByNumberState s) => s.isComplete),
      (bool? was, bool now) {
        if (now && !(was ?? false)) {
          final StickerAward award = ref
              .read(rewardsProvider.notifier)
              .awardById(state.template.stickerRewardId);
          showGameCelebration(
            context,
            onPlayAgain: vm.reset,
            stickerEmoji: award.sticker.emoji,
            isNewSticker: award.isNew,
          );
        }
      },
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Kept subtle so the palette colors stay true on the canvas.
          const ClayBackground(tint: AppColors.teal),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopBar(title: state.template.title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.colorByNumberHint,
                    textAlign: TextAlign.center,
                    style: clayBody(fontSize: 13.5),
                  ),
                ),
                Expanded(child: _Canvas(state: state, vm: vm, wobble: _wobble)),
                const SizedBox(height: 8),
                _NumberPalette(
                  selected: state.selectedNumber,
                  onSelect: vm.selectNumber,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
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
          ClayIconButton(
            icon: Icons.arrow_back_rounded,
            tint: AppColors.teal,
            onTap: () => context.pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: clayTitle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// The picture surface. Taps map to logical space and hit-test a region, which
/// the view-model fills (or nudges). The whole surface shakes on a wrong tap.
class _Canvas extends StatelessWidget {
  const _Canvas({required this.state, required this.vm, required this.wobble});

  final ByNumberState state;
  final ByNumberViewModel vm;
  final Animation<double> wobble;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Size size = constraints.biggest;
              final CanvasFit fit = CanvasFit.of(size, state.template.viewBox);

              void handleTap(Offset local) {
                final String? region =
                    state.template.hitTest(fit.toLogical(local));
                if (region != null) vm.tapRegion(region);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (TapUpDetails d) => handleTap(d.localPosition),
                child: AnimatedBuilder(
                  animation: wobble,
                  builder: (BuildContext context, Widget? child) {
                    final double dx = math.sin(wobble.value * math.pi * 4) *
                        6 *
                        (1 - wobble.value);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      isComplex: true,
                      size: Size.infinite,
                      painter: ColorByNumberPainter(
                        template: state.template,
                        fills: state.fills,
                        selectedNumber: state.selectedNumber,
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

/// The numbered swatch row. The selected number is enlarged and ringed.
class _NumberPalette extends StatelessWidget {
  const _NumberPalette({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (int n = 1; n <= kByNumberPalette.length; n++)
          _Swatch(
            number: n,
            color: kByNumberPalette[n - 1],
            selected: n == selected,
            onTap: () => onSelect(n),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.number,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double size = selected ? 54 : 46;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.dark : Colors.white,
            width: selected ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
