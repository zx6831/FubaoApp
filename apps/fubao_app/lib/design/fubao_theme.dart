import 'package:flutter/material.dart';

import 'fubao_colors.dart';

ThemeData buildFubaoTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: FubaoColors.mint,
    primary: FubaoColors.mint,
    secondary: FubaoColors.orange,
    error: FubaoColors.brick,
    surface: FubaoColors.card,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: FubaoColors.canvas,
    fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei', 'sans-serif'],
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.18,
        fontWeight: FontWeight.w800,
        color: FubaoColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: FubaoColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: FubaoColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: FubaoColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        height: 1.5,
        color: FubaoColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: FubaoColors.inkMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: FubaoColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 76,
      backgroundColor: FubaoColors.card,
      indicatorColor: FubaoColors.mintSoft,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
