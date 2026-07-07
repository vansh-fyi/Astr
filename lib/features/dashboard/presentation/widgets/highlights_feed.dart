import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../astronomy/domain/entities/astronomy_state.dart';
import '../../../astronomy/domain/entities/celestial_body.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../domain/entities/highlight_item.dart';
import '../../domain/logic/highlights_logic.dart';
import '../providers/highlight_time_provider.dart';
import 'celestial_detail_sheet.dart';

class HighlightsFeed extends ConsumerWidget {
  const HighlightsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AstronomyState> astronomyState = ref.watch(astronomyProvider);

    return astronomyState.when(
      data: (AstronomyState state) {
        final List<HighlightItem> highlights = HighlightsLogic.selectTop3(positions: state.positions);

        if (highlights.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "TONIGHT'S HIGHLIGHTS",
                    style: AppTypography.micro.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No bright objects above the horizon right now',
                    style: AppTypography.labelMd.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "TONIGHT'S HIGHLIGHTS",
                style: AppTypography.micro.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...highlights.map((HighlightItem item) => _HighlightItemWidget(item: item)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HighlightItemWidget extends ConsumerWidget {

  const _HighlightItemWidget({required this.item});
  final HighlightItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DateTime?> asyncTime = ref.watch(highlightTimeProvider(item.body));
    final String timeStr = asyncTime.when(
      data: (DateTime? time) => time != null ? DateFormat('HH:mm').format(time) : '--:--',
      loading: () => '...',
      error: (_, __) => '--:--',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.kCardRadius),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (BuildContext context) => CelestialDetailSheet(
                objectId: item.body.name.toLowerCase(),
                title: item.body.displayName,
                subtitle: 'Best view: $timeStr',
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Center(
                    child: Icon(
                      item.body == CelestialBody.moon ? Ionicons.moon_outline : Ionicons.planet_outline,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.body.displayName,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Best view: $timeStr',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Ionicons.chevron_forward,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
