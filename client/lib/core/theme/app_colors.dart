import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds & Surface
  static const Color background = Color(0xFF0F0F11);
  static const Color surface = Color(0xFF161619);
  static const Color surfaceElevated = Color(0xFF1E1E23);
  static const Color surfaceCard = Color(0xFF1A1A1F);
  static const Color surfaceInput = Color(0xFF18181C);
  static const Color border = Color(0xFF2B2B32);
  static const Color borderLight = Color(0xFF383842);

  // Primary Action Accent (Orange)
  static const Color orangePrimary = Color(0xFFFF6433);
  static const Color orangeHover = Color(0xFFFF7A4D);
  static const Color orangeDark = Color(0xFFE04E1E);
  static const Color orangeGlow = Color(0x33FF6433);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA7);
  static const Color textMuted = Color(0xFF6B6B75);

  // Board Specific Accent Colors
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF7A4D), Color(0xFFFF521D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magicSortGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x22FF6433), Color(0x00FF6433)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient forestGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFF7F1D1D), Color(0xFFC2410C)],
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF701A75), Color(0xFFC026D3)],
  );

  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF172554), Color(0xFF1E40AF)],
  );
}
