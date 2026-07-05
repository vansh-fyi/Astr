import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';

class TimeCard extends StatelessWidget {
  const TimeCard({
    super.key,
    required this.label,
    required this.time,
  });

  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            time != null ? DateFormat.Hm().format(time!) : '--:--',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
