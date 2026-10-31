/// Palettes claire et sombre, identiques à celles de la version Expo.
/// Les couleurs propres à l'app (carte du total, barres…) sont exposées via
/// une ThemeExtension : `context.colors.heroBackground`.
library;

import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.link,
    required this.danger,
    required this.heroBackground,
    required this.heroText,
    required this.heroTextMuted,
    required this.barTrack,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color link;
  final Color danger;
  final Color heroBackground;
  final Color heroText;
  final Color heroTextMuted;
  final Color barTrack;

  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD0D5DD),
    text: Color(0xFF101828),
    textMuted: Color(0xFF667085),
    primary: Color(0xFF175CD3),
    onPrimary: Color(0xFFFFFFFF),
    link: Color(0xFF175CD3),
    danger: Color(0xFFB42318),
    heroBackground: Color(0xFF102A43),
    heroText: Color(0xFFFFFFFF),
    heroTextMuted: Color(0xFFD9EAF7),
    barTrack: Color(0xFFEAECF0),
  );

  static const dark = AppColors(
    background: Color(0xFF0B1220),
    surface: Color(0xFF162032),
    border: Color(0xFF2E3A4F),
    text: Color(0xFFF2F4F7),
    textMuted: Color(0xFF98A2B3),
    primary: Color(0xFF2E90FA),
    onPrimary: Color(0xFFFFFFFF),
    link: Color(0xFF84CAFF),
    danger: Color(0xFFF97066),
    heroBackground: Color(0xFF1D3A5F),
    heroText: Color(0xFFFFFFFF),
    heroTextMuted: Color(0xFFD9EAF7),
    barTrack: Color(0xFF2E3A4F),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: brightness,
  ).copyWith(
    primary: c.primary,
    onPrimary: c.onPrimary,
    surface: c.surface,
    onSurface: c.text,
    error: c.danger,
    outline: c.border,
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c.border),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(backgroundColor: c.surface, foregroundColor: c.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      hintStyle: TextStyle(color: c.textMuted),
    ),
    extensions: [c],
  );
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
