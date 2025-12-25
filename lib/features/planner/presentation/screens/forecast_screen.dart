import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/widgets/cosmic_loader.dart';
import '../../domain/entities/daily_forecast.dart';
import '../providers/planner_provider.dart';
import '../widgets/forecast_list_item.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DailyForecast>> forecastAsync = ref.watch(forecastListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Assuming background is handled by parent or theme
      body: forecastAsync.when(
        data: (List<DailyForecast> forecasts) {
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
            separatorBuilder: (BuildContext context, int index) => const Gap(12),
            itemBuilder: (BuildContext context, int index) {
              return ForecastListItem(forecast: forecasts[index]);
            },
          );
        },
        loading: () => const Center(child: CosmicLoader()),
        error: (Object error, StackTrace stack) => Center(
          child: Text(
            'Error loading forecast: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
