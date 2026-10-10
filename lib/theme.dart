import 'package:flutter/material.dart';

/// DinePulse Moon Rose visual system for the owner portal.
class AppTheme {
  static const Color primary = Color(0xFFE03E65);
  static const Color primaryDark = Color(0xFFC83256);
  static const Color primaryLight = Color.fromRGBO(224, 62, 101, 0.15);
  static const Color primaryGlow = Color.fromRGBO(224, 62, 101, 0.35);
  static const Color accent = Color(0xFFFF6584);
  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color secondary = surfaceElevated;

  static const Color background = Color(0xFF0F0F15);
  static const Color surface = Color(0xFF1A1A26);
  static const Color surfaceElevated = Color(0xFF242436);
  static const Color surfaceHighlight = Color(0xFF2A2A40);
  static const Color cardBorder = Color(0xFF2E2E44);
  static const Color borderLight = Color(0xFF3D3D5A);
  static const Color borderFocus = primary;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color textMuted = Color(0xFF6E6E88);
  static const Color textInverse = background;
  static const Color overlay = Color.fromRGBO(10, 10, 16, 0.75);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color waitingBackground = Color.fromRGBO(255, 184, 0, 0.15);
  static const Color readyBackground = Color.fromRGBO(16, 185, 129, 0.15);
  static const Color arrivedBackground = Color.fromRGBO(59, 130, 246, 0.15);
  static const Color cancelledBackground = Color.fromRGBO(239, 68, 68, 0.15);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
        secondary: accent,
        onSecondary: textInverse,
        surfaceContainerHighest: surfaceHighlight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textSecondary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderFocus, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(color: cardBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        barrierColor: overlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        modalBackgroundColor: surfaceElevated,
        modalBarrierColor: overlay,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryLight,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: textSecondary)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : Colors.transparent),
        side: const BorderSide(color: borderLight),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? textPrimary : textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : surfaceHighlight),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: surfaceElevated, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        actionTextColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
