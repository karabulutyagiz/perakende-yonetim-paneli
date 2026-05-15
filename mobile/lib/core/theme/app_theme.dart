import 'package:flutter/material.dart';

class AppTheme {
  static const _seed =
      Color(0xFF0E6E4E); // zeytin yeşili — toptan/perakende hissi

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 25,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 62),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 62),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        extendedSizeConstraints: BoxConstraints(minHeight: 66),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        subtitleTextStyle: textTheme.bodyMedium,
        minVerticalPadding: 10,
      ),
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return light.copyWith(
        colorScheme: scheme, scaffoldBackgroundColor: scheme.surface);
  }

  // Borç durumu renkleri
  static const debtGreen = Color(0xFF22C55E);
  static const debtYellow = Color(0xFFF59E0B);
  static const debtRed = Color(0xFFEF4444);
  static const debtOverdue = Color(0xFF7F1D1D);
  static const debtPaid = Color(0xFF6B7280);

  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: base.displaySmall
              ?.copyWith(fontSize: 44, fontWeight: FontWeight.w800),
          headlineLarge: base.headlineLarge
              ?.copyWith(fontSize: 40, fontWeight: FontWeight.w800),
          headlineMedium: base.headlineMedium
              ?.copyWith(fontSize: 36, fontWeight: FontWeight.w800),
          headlineSmall: base.headlineSmall
              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
          titleLarge: base.titleLarge
              ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium
              ?.copyWith(fontSize: 23, fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          bodyMedium: base.bodyMedium
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          bodySmall: base.bodySmall
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge
              ?.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
          labelMedium: base.labelMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          labelSmall: base.labelSmall
              ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        )
        .apply(
          fontFamily: '.SF Pro Text',
          bodyColor: const Color(0xFF111827),
          displayColor: const Color(0xFF111827),
        );
  }
}
