import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';

class CloudBar extends StatefulWidget {

  const CloudBar({
    super.key,
    required this.cloudCoverPercentage,
    this.isLoading = false,
    this.errorMessage,
  });
  final double cloudCoverPercentage; // 0-100
  final bool isLoading;
  final String? errorMessage;

  @override
  State<CloudBar> createState() => _CloudBarState();
}

class _CloudBarState extends State<CloudBar> {


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppSpacing.kInnerRadius),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Cloud Cover',
                style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
              ),
              if (widget.isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                )
              else if (widget.errorMessage != null)
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16)
              else
                Text(
                  '${widget.cloudCoverPercentage.toInt()}%',
                  style: AppTypography.labelMd.copyWith(color: AppColors.textPrimary),
                ),
            ],
          ),
          const SizedBox(height: 13),
          if (widget.errorMessage != null)
            Text(
              widget.errorMessage!,
              style: AppTypography.labelSm.copyWith(color: Colors.redAccent),
            )
          else
            Container(
              height: AppSpacing.kCloudTrackHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cloudTrack,
                borderRadius: BorderRadius.circular(AppSpacing.kInnerRadius),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * (widget.cloudCoverPercentage / 100),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.accentSecondary,
                          boxShadow: AppColors.glowShadow,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
