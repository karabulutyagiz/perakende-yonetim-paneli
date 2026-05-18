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
          fontSize: 30,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 68),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 68),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 58),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        extendedSizeConstraints: BoxConstraints(minHeight: 72),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 60)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        subtitleTextStyle: textTheme.bodyMedium,
        minVerticalPadding: 12,
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
              ?.copyWith(fontSize: 48, fontWeight: FontWeight.w900),
          headlineLarge: base.headlineLarge
              ?.copyWith(fontSize: 44, fontWeight: FontWeight.w900),
          headlineMedium: base.headlineMedium
              ?.copyWith(fontSize: 40, fontWeight: FontWeight.w900),
          headlineSmall: base.headlineSmall
              ?.copyWith(fontSize: 36, fontWeight: FontWeight.w900),
          titleLarge: base.titleLarge
              ?.copyWith(fontSize: 30, fontWeight: FontWeight.w900),
          titleMedium: base.titleMedium
              ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
          titleSmall: base.titleSmall
              ?.copyWith(fontSize: 23, fontWeight: FontWeight.w800),
          bodyLarge: base.bodyLarge
              ?.copyWith(fontSize: 23, fontWeight: FontWeight.w700),
          bodyMedium: base.bodyMedium
              ?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
          bodySmall: base.bodySmall
              ?.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
          labelLarge: base.labelLarge
              ?.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
          labelMedium: base.labelMedium
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
          labelSmall: base.labelSmall
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        )
        .apply(
          fontFamily: '.SF Pro Text',
          bodyColor: const Color(0xFF0A0A0A),
          displayColor: const Color(0xFF0A0A0A),
        );
  }
}
