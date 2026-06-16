import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        surface: AppColors.cardLight,
        onSurface: AppColors.textLightPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textLightPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textLightSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0, // Flat design with subtle border & shadow instead
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.black,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        surface: AppColors.cardDark,
        onSurface: AppColors.textDarkPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textDarkPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textDarkPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textDarkPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textDarkSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
    );
  }
}
