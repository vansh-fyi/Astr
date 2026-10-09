import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color surface = Color(0xFF0C0F11);
  static const Color oledBlack = Color(0xFF000000);
  static const Color surfaceOverlay = Color(0x800C0F11);
  static const Color surfaceGlass = Color(0xCC0C0F11);
  static const Color accent = Color(0xFF448AFF);
  static const Color accentSecondary = Color(0xFF3A96FF);
  static const Color borderPrimary = Color(0xFF1B3766);
  static const Color borderSubtle = Color(0xFF0C1E33);
  static const Color borderSurface = Color(0xFF303A46);
  static const Color textPrimary = Color(0xFFF4F5F5);
  static const Color textSecondary = Color(0xFFDDDFE2);
  static const Color textMuted = Color(0xFFB3B7BC);
  static const Color textSubdued = Color(0xFF7D8792);
  static const Color zonePillFill = Color(0x333A96FF);
  static const Color zonePillText = Color(0xFFB0D5FF);
  static const Color ratingBarActive = Color(0xFF3A96FF);
  static const Color ratingBarInactive = Color(0x4D3C4957);
  static const Color cloudTrack = Color(0x4D3C4957);

  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(color: Color(0x40FFFFFF), blurRadius: 1),
    BoxShadow(color: Color(0xFF3A7FFF), blurRadius: 12.2, offset: Offset(0, 1)),
  ];
}
