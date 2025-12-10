import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/dashboard/domain/entities/highlight_item.dart';
import 'package:astr/features/dashboard/domain/logic/highlights_logic.dart';
import 'package:astr/features/dashboard/presentation/providers/highlight_time_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'celestial_detail_sheet.dart';
import 'package:astr/core/widgets/glass_panel.dart';

class HighlightsFeed extends ConsumerWidget {
  const HighlightsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astronomyState = ref.watch(astronomyProvider);

    return astronomyState.when(
      data: (state) {
        final highlights = HighlightsLogic.selectTop3(positions: state.positions);

        if (highlights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'TONIGHT\'S HIGHLIGHTS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...highlights.map((item) => _HighlightItemWidget(item: item)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HighlightItemWidget extends ConsumerWidget {
  final HighlightItem item;

  const _HighlightItemWidget({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTime = ref.watch(highlightTimeProvider(item.body));
    final timeStr = asyncTime.when(
      data: (time) => time != null ? DateFormat('HH:mm').format(time) : '--:--',
      loading: () => '...',
      error: (_, __) => '--:--',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassPanel(
        enableBlur: false,
        padding: const EdgeInsets.all(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CelestialDetailSheet(
              objectId: item.body.name.toLowerCase(),
              title: item.body.displayName,
              subtitle: 'Best view: $timeStr',
              themeColor: Colors.orange,
            ),
          );
        },
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: const Center(
                child: Icon(
                  Ionicons.planet_outline,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.body.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Best view: $timeStr',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Excellent', // Placeholder for quality logic
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Ionicons.chevron_forward,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
