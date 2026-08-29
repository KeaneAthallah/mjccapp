import 'package:flutter/material.dart';

/// Brand palette extracted from the Laravel website.
///
/// Values mirror the Tailwind v4 classes used in `/mjcc/resources/views/`
/// (emerald primary brand, blue secondary accent, gray neutrals).
@immutable
class AppColors {
  const AppColors._();

  // --- Primary brand (emerald) ---
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);

  // --- Secondary accent (blue) ---
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);

  // --- Status colors ---
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);

  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);

  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal700 = Color(0xFF0F766E);

  // --- Neutrals (gray) ---
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  static const Color white = Color(0xFFFFFFFF);

  // --- Semantic aliases ---
  static const Color primary = emerald600;
  static const Color primaryDark = emerald700;
  static const Color primaryDeep = emerald800;
  static const Color secondary = blue600;
  static const Color background = gray100;
  static const Color surface = white;
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textMuted = gray400;
  static const Color border = gray100;
  static const Color inputBorder = gray300;
  static const Color success = emerald600;
  static const Color warning = amber500;
  static const Color error = red600;
  static const Color info = blue600;

  /// Deep gradient used for the login background and welcome banner,
  /// matching the website's `from-emerald-800 via-emerald-700 to-blue-800`.
  static const List<Color> deepGradient = [
    emerald800,
    emerald700,
    blue800,
  ];

  /// Sidebar gradient: `from-gray-900 via-gray-900 to-emerald-700`.
  static const List<Color> sidebarGradient = [
    gray900,
    gray900,
    emerald700,
  ];
}
