import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../astronomy/domain/entities/moon_phase_info.dart';
import 'celestial_detail_sheet.dart';

class MoonMiniCard extends StatelessWidget {
  const MoonMiniCard({
    super.key,
    required this.moonPhaseInfo,
  });

  final MoonPhaseInfo moonPhaseInfo;

  @override
  Widget build(BuildContext context) {
    final String moonAsset = _getMoonAsset(moonPhaseInfo);
    final String moonPhaseLabel = _getMoonPhaseLabel(moonPhaseInfo);
    final int illuminationPercent = (moonPhaseInfo.illumination * 100).round();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (BuildContext ctx) => CelestialDetailSheet(
            objectId: 'moon',
            title: 'Moon',
            subtitle: moonPhaseLabel,
          ),
        );
      },
      child: RepaintBoundary(
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
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Text(
                      'MOON',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Text(
                      '$illuminationPercent%',
                      style: AppTypography.labelSm.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  Positioned(
                    top: 36,
                    left: 33,
                    width: 98,
                    height: 92,
                    child: Image.asset(
                      moonAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        moonPhaseLabel,
                        style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _getMoonAsset(MoonPhaseInfo info) {
    final double angle = info.phaseAngle;

    if (angle >= 355 || angle <= 5) return 'assets/img/moon_new.webp';
    if (angle > 5 && angle < 85) return 'assets/img/moon_waxing_crescent.webp';
    if (angle >= 85 && angle <= 95) return 'assets/img/moon_first_quarter.webp';
    if (angle > 95 && angle < 175) return 'assets/img/moon_waxing_gibbous.webp';
    if (angle >= 175 && angle <= 185) return 'assets/img/moon_full.webp';
    if (angle > 185 && angle < 265) return 'assets/img/moon_waning_gibbous.webp';
    if (angle >= 265 && angle <= 275) return 'assets/img/moon_last_quarter.webp';
    if (angle > 275 && angle < 355) return 'assets/img/moon_waning_crescent.webp';

    return 'assets/img/moon_waning_gibbous.webp';
  }

  static String _getMoonPhaseLabel(MoonPhaseInfo info) {
    final double angle = info.phaseAngle;

    if (angle >= 355 || angle <= 5) return 'New Moon';
    if (angle > 5 && angle < 85) return 'Waxing Crescent';
    if (angle >= 85 && angle <= 95) return 'First Quarter';
    if (angle > 95 && angle < 175) return 'Waxing Gibbous';
    if (angle >= 175 && angle <= 185) return 'Full Moon';
    if (angle > 185 && angle < 265) return 'Waning Gibbous';
    if (angle >= 265 && angle <= 275) return 'Last Quarter';
    if (angle > 275 && angle < 355) return 'Waning Crescent';

    return 'Moon';
  }
}
