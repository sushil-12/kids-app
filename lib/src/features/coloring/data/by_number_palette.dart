import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The Color-by-Number palette. The child picks a number, then taps the regions
/// labelled with it. Index 0 is "number 1", so `kByNumberPalette[n - 1]` is the
/// color for number `n`. Six bright, easy-to-tell-apart colors keep it simple
/// for young children.
const List<Color> kByNumberPalette = <Color>[
  AppColors.yellow, // 1
  AppColors.coral, // 2
  AppColors.teal, // 3
  AppColors.green, // 4
  AppColors.blue, // 5
  AppColors.purple, // 6
];

/// The color for a 1-based palette [number], or null if out of range.
Color? byNumberColor(int number) =>
    (number >= 1 && number <= kByNumberPalette.length)
        ? kByNumberPalette[number - 1]
        : null;
