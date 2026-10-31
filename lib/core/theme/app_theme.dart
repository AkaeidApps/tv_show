import 'package:flutter/material.dart';

/// Shared dark and light palettes for screens and reusable widgets.
class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFF070B18);
  static const Color surface = Color(0xFF111A2E);
  static const Color surfaceHigh = Color(0xFF1A2540);
  static const Color primary = Color(0xFF22D3EE);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFF472B6);
  static const Color live = Color(0xFF22C55E);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070B18), Color(0xFF0B1226), Color(0xFF150F33)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, accent],
  );

  static LinearGradient backgroundGradientFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? backgroundGradient
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F8FF), Color(0xFFEFF3FF), Color(0xFFF9EEFF)],
        );

  static Color surfaceFor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surfaceHighFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? surfaceHigh
      : const Color(0xFFE7EAF5);

  static Color foregroundFor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color mutedForegroundFor(BuildContext context) =>
      foregroundFor(context).withValues(alpha: 0.58);

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          surface: surface,
          onSurface: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
    );
  }

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF087F95),
          secondary: secondary,
          surface: const Color(0xFFFAFAFF),
          onSurface: const Color(0xFF171629),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF171629)),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF27283A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF087F95),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFAFAFF),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? const Color(0xFF171629)
                : const Color(0xFF171629).withValues(alpha: 0.58),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
