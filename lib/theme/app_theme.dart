import 'package:flutter/material.dart';

class AppColors {
  static const navyBg = Color(0xFF16294A);
  static const navBg = Color(0xFF0F172A);
  static const cardBg = Color(0xFF22385E);
  static const cardBorder = Color(0xFF33507B);
  static const accent = Color(0xFFF4A53A);
  static const textMuted = Color(0xFF9FB6D6);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1E8F5F);
  static const red = Color(0xFFFF6B6B);
  static const redDark = Color(0xFFC94C4C);

  static const pageBg = Color(0xFFF8FAFC);
  static const cardBgLight = Color(0xFFFFFFFF);
  static const cardBorderLight = Color(0xFFE2E8F0);

  static const navy = Color(0xFF0A2450);
  static const bodyText = Color(0xFF475569);
  static const mutedLight = Color(0xFF64748B);
  static const placeholderLight = Color(0xFF94A3B8);

  static const teal = Color(0xFF0D9488);
  static const tealBg = Color(0xFFCCFBF1);

  static const successGreen = Color(0xFF10B981);
  static const successGreenBg = Color(0xFFD1FAE5);

  static const dangerRed = Color(0xFFEF4444);
  static const dangerRedBg = Color(0xFFFEE2E2);

  static Color get neutralBadgeBg => navy.withValues(alpha: 0.08);
  static const neutralBadgeText = navy;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
  );
}