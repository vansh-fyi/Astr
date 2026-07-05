import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/engine/models/condition_result.dart';

class HeroConditionLabel extends StatelessWidget {
  const HeroConditionLabel({
    super.key,
    required this.conditionResult,
    required this.astrZone,
  });

  final ConditionResult? conditionResult;
  final int? astrZone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          conditionResult?.shortSummary ?? '--',
          style: AppTypography.display,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          conditionResult?.detailedAdvice ?? 'Loading sky conditions...',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceOverlay,
            borderRadius: BorderRadius.circular(AppSpacing.kBadgeRadius),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1,
            ),
          ),
          child: Text(
            'Zone ${astrZone ?? '--'}',
            style: AppTypography.labelMd,
          ),
        ),
      ],
    );
  }
}
