import 'package:flutter/material.dart';

import 'monte_colors.dart';

/// Light and dark [ThemeData] for Monte.
///
/// The font (Plus Jakarta Sans) is bundled in `assets/fonts`, so the app
/// never downloads anything to render text and works offline from the first
/// launch.
abstract final class MonteTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: MonteColors.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F6B45),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFF5C531),
      onSecondary: Color(0xFF0B3D2A),
      error: Color(0xFFC2372B),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF12261C),
      onSurfaceVariant: Color(0xFF5A6B62),
      surfaceContainerLowest: Color(0xFFF3F6F2),
      outlineVariant: Color(0x1412261C),
    ),
    background: const Color(0xFFF3F6F2),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: MonteColors.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF3DCB7D),
      onPrimary: Color(0xFF0A1410),
      secondary: Color(0xFFF5C531),
      onSecondary: Color(0xFF0B3D2A),
      error: Color(0xFFF2766A),
      onError: Color(0xFF0A1410),
      surface: Color(0xFF13211A),
      onSurface: Color(0xFFE6EFE9),
      onSurfaceVariant: Color(0xFF93A89C),
      surfaceContainerLowest: Color(0xFF0A1410),
      outlineVariant: Color(0x12FFFFFF),
    ),
    background: const Color(0xFF0A1410),
  );

  static ThemeData _build({
    required Brightness brightness,
    required MonteColors colors,
    required ColorScheme scheme,
    required Color background,
  }) {
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      extensions: [colors],
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.chip,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.chip,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension MonteThemeContext on BuildContext {
  /// Monte's brand and semantic colors for the current brightness.
  MonteColors get monte => Theme.of(this).extension<MonteColors>()!;
}
