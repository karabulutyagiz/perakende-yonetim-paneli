import 'package:flutter/material.dart';

/// Zirve Toptan tasarım sistemi — Getir benzeri: canlı marka rengi,
/// beyaz kartlar, yumuşak köşeler, telefon öncelikli boyutlar.
class AppColors {
  static const primary = Color(0xFF0B7A4B); // marka yeşili
  static const primaryDark = Color(0xFF06603A);
  static const primaryContainer = Color(0xFFD8F1E4);
  static const accent = Color(0xFFFFB703); // amber vurgu
  static const bg = Color(0xFFF3F5F4); // sayfa zemini
  static const surface = Colors.white;
  static const text = Color(0xFF15211B);
  static const textMuted = Color(0xFF66736C);
  static const line = Color(0xFFE4E9E6);
  static const danger = Color(0xFFE23D33);
  static const success = Color(0xFF22A45D);
}

class AppTheme {
  static const _seed = AppColors.primary;

  static ThemeData light({bool isTablet = false}) {
    final base = ThemeData(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, isTablet: isTablet);
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: const Color(0xFF3D2E00),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      outlineVariant: AppColors.line,
      error: AppColors.danger,
    );

    final buttonHeight = isTablet ? 60.0 : 52.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: isTablet ? 24 : 19,
          color: Colors.white,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 18 : 14,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.line, width: 1.4),
          foregroundColor: AppColors.text,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          iconSize: 22,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        extendedSizeConstraints: BoxConstraints(minHeight: 54),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        subtitleTextStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        iconColor: AppColors.textMuted,
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
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
              fontSize: isTablet ? 44 : 30, fontWeight: FontWeight.w900),
          headlineLarge: base.headlineLarge?.copyWith(
              fontSize: isTablet ? 38 : 26, fontWeight: FontWeight.w900),
          headlineMedium: base.headlineMedium?.copyWith(
              fontSize: isTablet ? 34 : 23, fontWeight: FontWeight.w800),
          headlineSmall: base.headlineSmall?.copyWith(
              fontSize: isTablet ? 30 : 21, fontWeight: FontWeight.w800),
          titleLarge: base.titleLarge?.copyWith(
              fontSize: isTablet ? 26 : 19, fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium?.copyWith(
              fontSize: isTablet ? 21 : 16, fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall?.copyWith(
              fontSize: isTablet ? 18 : 14, fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(
              fontSize: isTablet ? 19 : 15, fontWeight: FontWeight.w500),
          bodyMedium: base.bodyMedium?.copyWith(
              fontSize: isTablet ? 17 : 13.5, fontWeight: FontWeight.w500),
          bodySmall: base.bodySmall?.copyWith(
              fontSize: isTablet ? 15 : 12, fontWeight: FontWeight.w500),
          labelLarge: base.labelLarge?.copyWith(
              fontSize: isTablet ? 17 : 13, fontWeight: FontWeight.w700),
          labelMedium: base.labelMedium?.copyWith(
              fontSize: isTablet ? 15 : 12, fontWeight: FontWeight.w700),
          labelSmall: base.labelSmall?.copyWith(
              fontSize: isTablet ? 13 : 10.5, fontWeight: FontWeight.w700),
        )
        .apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        );
  }
}
