import 'package:flutter/material.dart';

/// Central color palette, mirrored from the Figma design system.
/// Kept as a single source of truth so theme + widgets stay consistent.
abstract final class AppColors {
  const AppColors._();

  static const Color cream = Color(0xFFFFF7EB);
  static const Color coral = Color(0xFFFF7361);
  static const Color teal = Color(0xFF2EBDB5);
  static const Color yellow = Color(0xFFFFCC40);
  static const Color purple = Color(0xFF8C73F2);
  static const Color dark = Color(0xFF332E40);
  static const Color pink = Color(0xFFFF99BF);
  static const Color pinkDeep = Color(0xFFE87CA3);
  static const Color green = Color(0xFF73CC73);
  static const Color blue = Color(0xFF5999F2);
  static const Color orange = Color(0xFFFF9E42);
  static const Color grey = Color(0xFFEBE8ED);

  /// Onboarding-flow accents (Figma file `oSqYkvClGfdzJ4YL2PeEuM`).
  static const Color indigo = Color(0xFF414FE0);
  static const Color crimson = Color(0xFFDF1A1D);
  static const Color ink = Color(0xFF16182C);
  static const Color slate = Color(0xFF6E6A7C);

  /// [dark] at 55% alpha — bottom scrim over story illustrations so
  /// subtitles stay readable on any art. Const so gradients can be const.
  static const Color darkScrim = Color(0x8C332E40);

  /// The 12-swatch coloring palette, in display order.
  static const List<Color> crayonPalette = <Color>[
    coral,
    orange,
    yellow,
    green,
    teal,
    blue,
    purple,
    pink,
    dark,
    Color(0xFF99663F),
    Colors.white,
    grey,
  ];
}
