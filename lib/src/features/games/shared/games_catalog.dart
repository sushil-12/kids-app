import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clay_icons.dart';
import '../../../l10n/app_localizations.dart';

/// Age bands the games are grouped under on the hub (see CLAUDE.md §1).
enum GameBand { junior, senior }

/// Static description of one game for the hub list. Titles are resolved from
/// [AppLocalizations] at build time so the catalog itself stays `const`.
@immutable
class GameInfo {
  const GameInfo({
    required this.route,
    required this.title,
    required this.color,
    required this.glyph,
    required this.band,
  });

  final String route;
  final String Function(AppLocalizations l10n) title;
  final Color color;
  final ClayIconKind glyph;
  final GameBand band;
}

String _shapeSorter(AppLocalizations l) => l.gameShapeSorter;
String _colorMatch(AppLocalizations l) => l.gameColorMatch;
String _memoryFlip(AppLocalizations l) => l.gameMemoryFlip;
String _letterTrace(AppLocalizations l) => l.gameLetterTrace;
String _countTap(AppLocalizations l) => l.gameCountTap;
String _pattern(AppLocalizations l) => l.gamePattern;
String _oddOneOut(AppLocalizations l) => l.gameOddOneOut;

/// The five Phase-1 games, in hub display order.
const List<GameInfo> kGames = <GameInfo>[
  GameInfo(
    route: Routes.gameShapeSorter,
    title: _shapeSorter,
    color: AppColors.coral,
    glyph: ClayIconKind.shapes,
    band: GameBand.junior,
  ),
  GameInfo(
    route: Routes.gameColorMatch,
    title: _colorMatch,
    color: AppColors.teal,
    glyph: ClayIconKind.palette,
    band: GameBand.junior,
  ),
  GameInfo(
    route: Routes.gameMemoryFlip,
    title: _memoryFlip,
    color: AppColors.purple,
    glyph: ClayIconKind.cards,
    band: GameBand.junior,
  ),
  GameInfo(
    route: Routes.gameOddOneOut,
    title: _oddOneOut,
    color: AppColors.pink,
    glyph: ClayIconKind.magnifier,
    band: GameBand.junior,
  ),
  GameInfo(
    route: Routes.gameLetterTrace,
    title: _letterTrace,
    color: AppColors.blue,
    glyph: ClayIconKind.trace,
    band: GameBand.senior,
  ),
  GameInfo(
    route: Routes.gameCountTap,
    title: _countTap,
    color: AppColors.orange,
    glyph: ClayIconKind.apples,
    band: GameBand.senior,
  ),
  GameInfo(
    route: Routes.gamePattern,
    title: _pattern,
    color: AppColors.green,
    glyph: ClayIconKind.pattern,
    band: GameBand.senior,
  ),
];

/// The games belonging to one age [band], in catalog order.
List<GameInfo> gamesForBand(GameBand band) =>
    kGames.where((GameInfo g) => g.band == band).toList(growable: false);
