import 'package:flutter/material.dart';

class AppTheme {
  static const _seed =
      Color(0xFF0E6E4E); // zeytin yeşili — toptan/perakende hissi

  static ThemeData light({bool isTablet = false}) {
    final base = ThemeData(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, isTablet: isTablet);
    final inputVerticalPadding = isTablet ? 20.0 : 10.0;
    final inputHorizontalPadding = isTablet ? 18.0 : 12.0;
    final buttonHeight = isTablet ? 68.0 : 44.0;
    final buttonHorizontalPadding = isTablet ? 28.0 : 14.0;
    final buttonVerticalPadding = isTablet ? 20.0 : 10.0;
    final textButtonHeight = isTablet ? 58.0 : 38.0;
    final segmentedHeight = isTablet ? 60.0 : 38.0;
    final chipVerticalPadding = isTablet ? 12.0 : 6.0;
    final listTilePadding = isTablet ? 12.0 : 4.0;
    final appBarTitleSize = isTablet ? 30.0 : 18.0;
    final iconButtonMinSize = isTablet ? 52.0 : 38.0;
    final iconButtonIconSize = isTablet ? 24.0 : 20.0;
    final iconButtonPadding = isTablet ? 12.0 : 8.0;
    final fabMinHeight = isTablet ? 72.0 : 52.0;

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
          fontSize: appBarTitleSize,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: inputHorizontalPadding,
          vertical: inputVerticalPadding,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: buttonHorizontalPadding,
            vertical: buttonVerticalPadding,
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: buttonHorizontalPadding,
            vertical: buttonVerticalPadding,
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, textButtonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 12,
            vertical: isTablet ? 16 : 8,
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(iconButtonMinSize, iconButtonMinSize),
          iconSize: iconButtonIconSize,
          padding: EdgeInsets.all(iconButtonPadding),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedSizeConstraints: BoxConstraints(minHeight: fabMinHeight),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          minimumSize: WidgetStatePropertyAll(Size(0, segmentedHeight)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: isTablet ? 18 : 10,
              vertical: isTablet ? 14 : 6,
            ),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        padding:
            EdgeInsets.symmetric(horizontal: 12, vertical: chipVerticalPadding),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        subtitleTextStyle: textTheme.bodyMedium,
        minVerticalPadding: listTilePadding,
      ),
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return light()
        .copyWith(colorScheme: scheme, scaffoldBackgroundColor: scheme.surface);
  }

  // Borç durumu renkleri
  static const debtGreen = Color(0xFF22C55E);
  static const debtYellow = Color(0xFFF59E0B);
  static const debtRed = Color(0xFFEF4444);
  static const debtOverdue = Color(0xFF7F1D1D);
  static const debtPaid = Color(0xFF6B7280);

  static TextTheme _buildTextTheme(TextTheme base, {required bool isTablet}) {
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
              fontSize: isTablet ? 48 : 28, fontWeight: FontWeight.w900),
          headlineLarge: base.headlineLarge?.copyWith(
              fontSize: isTablet ? 44 : 24, fontWeight: FontWeight.w900),
          headlineMedium: base.headlineMedium?.copyWith(
              fontSize: isTablet ? 40 : 22, fontWeight: FontWeight.w800),
          headlineSmall: base.headlineSmall?.copyWith(
              fontSize: isTablet ? 36 : 20, fontWeight: FontWeight.w800),
          titleLarge: base.titleLarge?.copyWith(
              fontSize: isTablet ? 30 : 18, fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium?.copyWith(
              fontSize: isTablet ? 26 : 15, fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall?.copyWith(
              fontSize: isTablet ? 23 : 12, fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(
              fontSize: isTablet ? 23 : 14, fontWeight: FontWeight.w500),
          bodyMedium: base.bodyMedium?.copyWith(
              fontSize: isTablet ? 21 : 13, fontWeight: FontWeight.w500),
          bodySmall: base.bodySmall?.copyWith(
              fontSize: isTablet ? 19 : 11, fontWeight: FontWeight.w500),
          labelLarge: base.labelLarge?.copyWith(
              fontSize: isTablet ? 22 : 12, fontWeight: FontWeight.w700),
          labelMedium: base.labelMedium?.copyWith(
              fontSize: isTablet ? 20 : 11, fontWeight: FontWeight.w700),
          labelSmall: base.labelSmall?.copyWith(
              fontSize: isTablet ? 18 : 9, fontWeight: FontWeight.w700),
        )
        .apply(
          fontFamily: '.SF Pro Text',
          bodyColor: const Color(0xFF0A0A0A),
          displayColor: const Color(0xFF0A0A0A),
        );
  }
}
