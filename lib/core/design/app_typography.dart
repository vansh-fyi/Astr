import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const TextStyle display = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 72,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.6,
    color: AppColors.textMuted,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 8,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.4,
    color: AppColors.textMuted,
  );

  static TextStyle get nav => GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppColors.textPrimary,
      );
}
