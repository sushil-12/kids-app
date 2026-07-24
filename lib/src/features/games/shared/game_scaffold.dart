import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_decor.dart';

/// Shared chrome for every brain game: a back button, a row of progress stars,
/// and a bright instruction banner. The game's interactive surface is [child].
///
/// Games stay view-only — they pass their current [progress] / [total] and the
/// localized [instruction]; this widget owns no game logic. It also reads the
/// instruction aloud whenever it changes (e.g. each new round), so every game
/// gets spoken prompts for free.
class GameScaffold extends ConsumerStatefulWidget {
  const GameScaffold({
    required this.instruction,
    required this.progress,
    required this.total,
    required this.child,
    this.accent = AppColors.teal,
    super.key,
  });

  /// Localized "what to do" line shown in the banner.
  final String instruction;

  /// Completed steps and the total, drawn as filled / empty stars.
  final int progress;
  final int total;

  /// Banner + star tint.
  final Color accent;

  /// The game's play surface.
  final Widget child;

  @override
  ConsumerState<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends ConsumerState<GameScaffold> {
  @override
  void initState() {
    super.initState();
    _speakInstruction();
  }

  @override
  void didUpdateWidget(GameScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-read only when the prompt actually changes (a new round/puzzle), not on
    // every in-round rebuild.
    if (oldWidget.instruction != widget.instruction) _speakInstruction();
  }

  void _speakInstruction() =>
      ref.read(audioServiceProvider).speak(widget.instruction);

  @override
  Widget build(BuildContext context) {
    final String instruction = widget.instruction;
    final int progress = widget.progress;
    final int total = widget.total;
    final Color accent = widget.accent;
    final Widget child = widget.child;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Pastel-clay backdrop tinted per game (design language, CLAUDE.md §9).
          ClayBackground(tint: accent),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: <Widget>[
                      ClayIconButton(
                        icon: Icons.arrow_back_rounded,
                        tint: accent,
                        onTap: () => context.pop(),
                      ),
                      Expanded(
                        child: _Stars(
                          progress: progress,
                          total: total,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      instruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(child: child),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({
    required this.progress,
    required this.total,
    required this.color,
  });

  final int progress;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Scale the star row down when a game has many rounds, so it never overflows
    // the available width; stays full-size when there's room.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                i < progress ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < progress
                    ? AppColors.yellow
                    : color.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}
