import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/view/win_celebration.dart';
import '../../shared/game_scaffold.dart';
import '../view_model/letter_trace_view_model.dart';

/// Letter Trace (ages 5–6) — sweep a finger through the guide dots of a letter.
class LetterTraceScreen extends ConsumerStatefulWidget {
  const LetterTraceScreen({super.key});

  @override
  ConsumerState<LetterTraceScreen> createState() => _LetterTraceScreenState();
}

class _LetterTraceScreenState extends ConsumerState<LetterTraceScreen> {
  @override
  void initState() {
    super.initState();
    // The provider outlives this screen, so returning to it (e.g. the child
    // tapped back instead of "Again!") would otherwise show a fully-lit,
    // already-complete letter that never re-fires its celebration and can't be
    // progressed. Advancing on re-entry hands them a fresh letter instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(letterTraceProvider).isComplete) {
        ref.read(letterTraceProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Size size = constraints.biggest;

                  void handlePoint(Offset local) => vm.touch(
                        Offset(local.dx / size.width, local.dy / size.height),
                      );

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (DragStartDetails d) =>
                        handlePoint(d.localPosition),
                    onPanUpdate: (DragUpdateDetails d) =>
                        handlePoint(d.localPosition),
                    onPanEnd: (_) => vm.liftPen(),
                    onTapDown: (TapDownDetails d) =>
                        handlePoint(d.localPosition),
                    child: Stack(
                      children: <Widget>[
                        // Faint guide glyph behind the dots, built from the same
                        // strokes the dots sit on so the two always line up.
                        RepaintBoundary(
                          child: CustomPaint(
                            size: size,
                            painter: _GuidePainter(
                              strokes: state.strokes,
                              color: AppColors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        // Ink trail drawn by the child's finger.
                        RepaintBoundary(
                          child: CustomPaint(
                            size: size,
                            painter: _TracePainter(
                              points: state.drawnPoints,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        // Guide dots.
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
      ),
    );
  }
}

/// Draws the faint letter the child traces over, smoothing each normalized
/// stroke polyline into a rounded curve so even few control points read as a
/// proper glyph. Shares its stroke data with the guide dots, guaranteeing they
/// line up exactly.
class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = size.shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final List<Offset> stroke in strokes) {
      if (stroke.isEmpty) continue;
      final List<Offset> pts = <Offset>[
        for (final Offset p in stroke)
          Offset(p.dx * size.width, p.dy * size.height),
      ];
      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      if (pts.length == 2) {
        path.lineTo(pts[1].dx, pts[1].dy);
      } else {
        // Quadratic curve through the midpoints of consecutive points.
        for (int i = 1; i < pts.length - 1; i++) {
          final Offset mid = (pts[i] + pts[i + 1]) / 2;
          path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
        }
        path.lineTo(pts.last.dx, pts.last.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => !identical(old.strokes, strokes);
}

/// Draws the ink trail. Sentinel `Offset(-1, -1)` breaks the path into
/// separate sub-paths (one per continuous finger stroke).
class _TracePainter extends CustomPainter {
  const _TracePainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  static const double _sentinel = -1;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    bool penDown = false;

    for (final Offset p in points) {
      if (p.dx == _sentinel && p.dy == _sentinel) {
        penDown = false;
        continue;
      }
      final Offset pixel = Offset(p.dx * size.width, p.dy * size.height);
      if (!penDown) {
        path.moveTo(pixel.dx, pixel.dy);
        penDown = true;
      } else {
        path.lineTo(pixel.dx, pixel.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TracePainter old) => old.points.length != points.length;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.center, required this.lit});

  final Offset center;
  final bool lit;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - _size / 2,
      top: center.dy - _size / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: lit ? AppColors.green : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: lit ? AppColors.green : AppColors.blue,
            width: 3,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (lit ? AppColors.green : AppColors.blue)
                  .withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: lit
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
