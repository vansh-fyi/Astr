import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../domain/entities/light_pollution.dart';

class VisibilityMiniCard extends StatelessWidget {
  const VisibilityMiniCard({
    super.key,
    required this.lightPollution,
  });

  final LightPollution lightPollution;

  @override
  Widget build(BuildContext context) {
    final int astrZone = lightPollution.visibilityIndex;
    final int activeBars = ((astrZone - 1) / 2).floor().clamp(0, 5);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            width: AppSpacing.kMiniCardWidth,
            height: AppSpacing.kMiniCardHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
            ),
            child: Stack(
              children: <Widget>[
                // Label 'VISIBILITY'
                Positioned(
                  top: 15,
                  left: 15,
                  child: Text(
                    'VISIBILITY',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                ),
                // Zone pill
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.zonePillFill,
                      borderRadius: BorderRadius.circular(AppSpacing.kBadgeRadius),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      'Zone $astrZone',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.zonePillText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Sky type label (e.g. "Rural Sky")
                Positioned(
                  top: 50,
                  left: 15,
                  child: Text(
                    _getSkyLabel(astrZone),
                    style: AppTypography.title.copyWith(fontSize: 28, letterSpacing: -0.5),
                  ),
                ),
                // MPSAS value
                Positioned(
                  top: 86,
                  left: 15,
                  child: Text(
                    '${lightPollution.mpsas.toStringAsFixed(2)} MPSAS',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                ),
                // Rating bars
                Positioned(
                  bottom: 15,
                  left: 15,
                  right: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List<Widget>.generate(5, (int index) {
                      final bool isActive = index < activeBars;
                      return Container(
                        width: (AppSpacing.kRatingBarsWidth - 4 * AppSpacing.kRatingBarGap) / 5,
                        height: AppSpacing.kRatingBarHeight,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.ratingBarActive : AppColors.ratingBarInactive,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isActive ? AppColors.glowShadow : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getSkyLabel(int zone) {
    if (zone <= 2) return 'Dark Sky';
    if (zone <= 4) return 'Rural Sky';
    if (zone <= 6) return 'Suburban Sky';
    return 'Urban Sky';
  }
}
