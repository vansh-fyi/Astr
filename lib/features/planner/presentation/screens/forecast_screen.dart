import 'package:astr/core/widgets/cosmic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:astr/features/planner/presentation/widgets/forecast_list_item.dart';
import 'package:gap/gap.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Assuming background is handled by parent or theme
      body: forecastAsync.when(
        data: (forecasts) {
          if (forecasts.isEmpty) {
            return const Center(
              child: Text(
                'No forecast data available.\nPlease ensure location is set.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: forecasts.length,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              return ForecastListItem(forecast: forecasts[index]);
            },
          );
        },
        loading: () => const Center(child: CosmicLoader()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading forecast: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
