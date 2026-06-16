import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Ocean Blue & Mint Teal)
  static const Color primary = Color(0xFF0EA5E9); // Ocean Blue (Sky 500)
  static const Color primaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color primaryDark = Color(0xFF0369A1); // Sky 700
  
  static const Color secondary = Color(0xFF14B8A6); // Mint Teal (Teal 500)
  static const Color secondaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color secondaryDark = Color(0xFF0F766E); // Teal 700

  // Neutrals (Light Mode - Eye-Friendly Off-White)
  static const Color bgLight = Color(0xFFFAFAFA); // Calm white background (#FAFAFA)
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White Surface
  static const Color textLightPrimary = Color(0xFF111827); // Solid crisp near-black for primary text
  static const Color textLightSecondary = Color(0xFF64748B); // Slate 500 (Muted)
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200 (Subtle borders)
  static const Color inputBgLight = Color(0xFFF1F5F9); // Slate 100 (Filled input background)

  // Neutrals (Dark Mode - Smooth Slate Dark)
  static const Color bgDark = Color(0xFF0F172A); // Slate 900 (Deep modern Slate)
  static const Color cardDark = Color(0xFF1E293B); // Slate 800 (Surface Card)
  static const Color textDarkPrimary = Color(0xFFF8FAFC); // Slate 50 (Off-white text)
  static const Color textDarkSecondary = Color(0xFF94A3B8); // Slate 400 (Muted)
  static const Color borderDark = Color(0xFF334155); // Slate 700 (Subtle dark borders)
  static const Color inputBgDark = Color(0xFF1E293B); // Slate 800 (Filled input background)

  // Semantic/Status Colors (Soft, Muted)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF0EA5E9); // Sky 500

  // Soft Shadows (Low opacity, high blur)
  static final List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.01),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> darkShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
