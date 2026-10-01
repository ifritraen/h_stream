import 'package:flutter/material.dart';

class AppTheme {
  // Pure Pitch-Black OLED Palette
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0C0D0F);
  static const Color surfaceElevated = Color(0xFF121316);
  static const Color surfaceCard = Color(0xFF17181C);
  static const Color surfaceHighlight = Color(0xFF202127);
  
  // Refined Accents (Anymex / High-End Streaming Red & Soft Secondary)
  static const Color primaryAccent = Color(0xFFE50914);
  static const Color primaryNeon = primaryAccent; // Backwards-compatible alias
  static const Color primaryGlow = Color(0x20E50914);
  
  static const Color secondaryAccent = Color(0xFF38BDF8);
  static const Color secondaryNeon = secondaryAccent; // Backwards-compatible alias
  static const Color secondaryGlow = Color(0x2038BDF8);
  
  static const Color accentGold = Color(0xFFFBBF24); // Star ratings / Premium
  static const Color accentPurple = Color(0xFFA78BFA); // 3D / Tags
  static const Color accentGreen = Color(0xFF34D399); // Whitelist / Active

  // Neutrals & Clean Dark Glass
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white hairline
  static const Color borderBright = Color(0x24FFFFFF); // 14% white border
  static const Color glassBackground = Color(0xE60A0A0D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      cardColor: surfaceCard,
      dividerColor: borderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryAccent,
        unselectedItemColor: textMuted,
      ),
    );
  }

  // Modern Clean Container Decoration
  static BoxDecoration glassBox({
    double radius = 14,
    Color? color,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? glassBackground,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: borderSubtle, width: 0.8),
      boxShadow: shadows ?? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Soft Focus Box Decoration (replaces harsh neon glow)
  static BoxDecoration neonGlowBox({
    required Color color,
    double radius = 14,
    double glowSpread = 4,
  }) {
    return BoxDecoration(
      color: surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: glowSpread,
          spreadRadius: 0,
        )
      ],
    );
  }
}
