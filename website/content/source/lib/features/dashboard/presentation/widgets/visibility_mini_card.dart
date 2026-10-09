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
    // Inverted: Zone 1 (dark sky, best) → 5 bars; Zone 9 (city, worst) → 1 bar.
    // Before: ((astrZone - 1) / 2).floor() gave 0 bars for Zone 1 (wrong).
    final int activeBars = (5 - ((astrZone - 1) / 2).floor()).clamp(0, 5);

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
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Label and zone pill share one row, centred on each other.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'VISIBILITY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sky label (e.g. "Rural Sky"): 20 px so the longest, "Suburban Sky",
                  // fits on one line; scaled down further if a font is wider.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _getSkyLabel(astrZone),
                          maxLines: 1,
                          style: AppTypography.title.copyWith(
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // MPSAS value sits directly above the rating bars.
                  Text(
                    '${lightPollution.mpsas.toStringAsFixed(2)} MPSAS',
                    style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  // Rating bars
                  Row(
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
                ],
              ),
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
