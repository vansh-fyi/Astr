import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/engine/models/condition_result.dart';
import '../../../catalog/domain/entities/celestial_object.dart';
import '../../../catalog/presentation/providers/object_detail_notifier.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import '../../domain/entities/weather.dart';
import '../providers/condition_quality_provider.dart';
import '../providers/weather_provider.dart';
import 'atmospherics_sheet.dart';
import 'cloud_bar.dart';

class ConditionsCard extends ConsumerWidget {
  const ConditionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch weatherProvider for cloud cover
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
    // Watch conditionQualityProvider for title/subtitle
    final AsyncValue<ConditionResult> conditionQualityAsync = ref.watch(conditionQualityProvider);

    final double cloudCover = weatherAsync.valueOrNull?.cloudCover ?? 0.0;
    final bool isWeatherLoading = weatherAsync.isLoading;
    final String? weatherError = weatherAsync.hasError ? weatherAsync.error.toString() : null;

    final String titleText = conditionQualityAsync.valueOrNull?.shortSummary
        ?? 'Clear Skies';
    final String subtitleText = conditionQualityAsync.valueOrNull?.detailedAdvice
        ?? 'Perfect visibility for observation';

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            width: double.infinity,
            height: AppSpacing.kConditionsCardHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
            ),
            child: Stack(
              children: <Widget>[
                // Header row: left=16, top=16, right=16
                Positioned(
                  left: AppSpacing.kCardPadding,
                  top: AppSpacing.kCardPadding,
                  right: AppSpacing.kCardPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(
                        width: 180, // slightly wider to accommodate longer titles/subtitles comfortably
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              titleText,
                              style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleText,
                              style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      // Explore Button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            useRootNavigator: true,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (BuildContext context) => const AtmosphericsSheet(),
                          );
                        },
                        child: Container(
                          width: AppSpacing.kExploreButtonWidth,
                          height: AppSpacing.kExploreButtonHeight,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppSpacing.kExploreButtonRadius),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Explore',
                            style: AppTypography.labelMd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cloud Cover: left=16, top=69, right=16
                Positioned(
                  left: AppSpacing.kCardPadding,
                  top: AppSpacing.kCloudSectionTop,
                  right: AppSpacing.kCardPadding,
                  child: CloudBar(
                    cloudCoverPercentage: cloudCover,
                    isLoading: isWeatherLoading,
                    errorMessage: weatherError,
                  ),
                ),

                // Rise/Set cells: left=16, top=162, right=16, height=64
                Positioned(
                  left: AppSpacing.kCardPadding,
                  top: 162,
                  right: AppSpacing.kCardPadding,
                  height: AppSpacing.kSunMoonCellHeight,
                  child: Consumer(
                    builder: (BuildContext context, WidgetRef ref, Widget? child) {
                      final ObjectDetailState sunState = ref.watch(objectDetailNotifierProvider('sun'));
                      final ObjectDetailState moonState = ref.watch(objectDetailNotifierProvider('moon'));
                      
                      final CelestialObject? sun = sunState.object;
                      final CelestialObject? moon = moonState.object;

                      DateTime? sunRise;
                      DateTime? sunSet;
                      DateTime? moonRise;
                      DateTime? moonSet;

                      if (sun != null) {
                        final Map<String, DateTime?>? sunTimes = ref.watch(riseSetProvider(sun)).valueOrNull;
                        if (sunTimes != null) {
                          sunRise = sunTimes['rise'];
                          sunSet = sunTimes['set'];
                        }
                      }

                      if (moon != null) {
                        final Map<String, DateTime?>? moonTimes = ref.watch(riseSetProvider(moon)).valueOrNull;
                        if (moonTimes != null) {
                          moonRise = moonTimes['rise'];
                          moonSet = moonTimes['set'];
                        }
                      }

                      return Row(
                        children: <Widget>[
                          Expanded(child: _TimeCell(label: 'SUNRISE', time: sunRise)),
                          const SizedBox(width: 8),
                          Expanded(child: _TimeCell(label: 'SUNSET', time: sunSet)),
                          const SizedBox(width: 8),
                          Expanded(child: _TimeCell(label: 'MOONRISE', time: moonRise)),
                          const SizedBox(width: 8),
                          Expanded(child: _TimeCell(label: 'MOONSET', time: moonSet)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.label,
    required this.time,
  });

  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final String timeStr = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      height: AppSpacing.kSunMoonCellHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppSpacing.kInnerRadius),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: AppSpacing.kSunMoonLabelTop,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                label,
                style: AppTypography.micro.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.kSunMoonTimeTop,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                timeStr,
                style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
