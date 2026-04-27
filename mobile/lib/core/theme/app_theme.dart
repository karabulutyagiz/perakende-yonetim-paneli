import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF0E6E4E); // zeytin yeşili — toptan/perakende hissi

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return light.copyWith(colorScheme: scheme, scaffoldBackgroundColor: scheme.surface);
  }

  // Borç durumu renkleri
  static const debtGreen = Color(0xFF22C55E);
  static const debtYellow = Color(0xFFF59E0B);
  static const debtRed = Color(0xFFEF4444);
  static const debtOverdue = Color(0xFF7F1D1D);
  static const debtPaid = Color(0xFF6B7280);
}
