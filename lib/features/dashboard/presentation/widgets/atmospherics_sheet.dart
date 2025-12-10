import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../providers/weather_provider.dart';
import '../providers/darkness_provider.dart';
import '../providers/prime_view_provider.dart';
import 'conditions_graph.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/features/catalog/presentation/providers/rise_set_provider.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_graph_notifier.dart';
import 'package:intl/intl.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/dashboard/presentation/widgets/time_card.dart';
import 'package:astr/features/dashboard/presentation/widgets/graph_legend_item.dart';
import 'package:astr/features/dashboard/presentation/theme/graph_theme.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/night_window_provider.dart';

class AtmosphericsSheet extends ConsumerWidget {
  const AtmosphericsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final darknessAsync = ref.watch(darknessProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            // 1. Background (Fixed)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: const Color(0xFF0A0A0B).withValues(alpha: 0.8),
                ),
              ),
            ),

            // 2. Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 130, 24, 48 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Legend
                    const Row(
                      children: [
                        GraphLegendItem(label: 'MOON', color: GraphTheme.moonColor),
                        SizedBox(width: 12),
                        GraphLegendItem(label: 'CLOUD COVER', color: GraphTheme.cloudCoverColor),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Conditions Graph
                    // Conditions Graph
                    Consumer(
                      builder: (context, ref, child) {
                        final nightWindowAsync = ref.watch(nightWindowProvider);
                        
                        return nightWindowAsync.when(
                          data: (nightWindow) {
                            final startTime = nightWindow['start']!;
                            final endTime = nightWindow['end']!;

                            final moonState = ref.watch(objectDetailNotifierProvider('moon'));
                            final moon = moonState.object;
                            
                            DateTime? moonRise;
                            if (moon != null) {
                                final riseSetAsync = ref.watch(riseSetProvider(moon));
                                final times = riseSetAsync.valueOrNull;
                                if (times != null && times['rise'] != null) {
                                    moonRise = times['rise'];
                                }
                            }

                            // Fetch Moon Graph Data for the curve
                            final moonGraphState = ref.watch(visibilityGraphProvider('moon'));
                            final moonCurve = moonGraphState.graphData?.objectCurve;

                            // Fetch Cloud Cover Data
                            final hourlyForecastAsync = ref.watch(hourlyForecastProvider);
                            final cloudCoverData = hourlyForecastAsync.valueOrNull;

                            // Fetch Prime View Window
                            final primeViewAsync = ref.watch(primeViewProvider);
                            final primeViewWindow = primeViewAsync.valueOrNull;

                            return Container(
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ConditionsGraph(
                                      startTime: startTime,
                                      endTime: endTime,
                                      moonRiseTime: moonRise,
                                      themeColor: Colors.indigo,
                                      moonCurve: moonCurve,
                                      cloudCoverData: cloudCoverData,
                                      primeViewWindow: primeViewWindow,
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, stack) => SizedBox(
                            height: 200,
                            child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                          ),
                        );
                      }
                    ),

                    // Rise/Set Cards
                    Consumer(
                      builder: (context, ref, child) {
                        final sunState = ref.watch(objectDetailNotifierProvider('sun'));
                        final moonState = ref.watch(objectDetailNotifierProvider('moon'));
                        
                        final sun = sunState.object;
                        final moon = moonState.object;

                        DateTime? sunRise;
                        DateTime? sunSet;
                        DateTime? moonRise;
                        DateTime? moonSet;

                        if (sun != null) {
                            final sunTimes = ref.watch(riseSetProvider(sun)).valueOrNull;
                            if (sunTimes != null) {
                                sunRise = sunTimes['rise'];
                                sunSet = sunTimes['set'];
                            }
                        }

                        if (moon != null) {
                            final moonTimes = ref.watch(riseSetProvider(moon)).valueOrNull;
                            if (moonTimes != null) {
                                moonRise = moonTimes['rise'];
                                moonSet = moonTimes['set'];
                            }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            children: [
                              Expanded(child: TimeCard(label: 'SUNRISE', time: sunRise)),
                              const SizedBox(width: 8),
                              Expanded(child: TimeCard(label: 'SUNSET', time: sunSet)),
                              const SizedBox(width: 8),
                              Expanded(child: TimeCard(label: 'MOONRISE', time: moonRise)),
                              const SizedBox(width: 8),
                              Expanded(child: TimeCard(label: 'MOONSET', time: moonSet)),
                            ],
                          ),
                        );
                      },
                    ),

                    // Grid
                    weatherAsync.when(
                      data: (weather) {
                        // Seeing Color Logic
                        Color seeingColor = Colors.white;
                        if (weather.seeingScore != null) {
                          if (weather.seeingScore! >= 8) {
                            seeingColor = Colors.greenAccent;
                          } else if (weather.seeingScore! >= 5) {
                            seeingColor = Colors.yellowAccent;
                          } else {
                            seeingColor = Colors.redAccent;
                          }
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            // Seeing
                            _buildMetricCard(
                              icon: Ionicons.eye_outline,
                              label: 'Seeing',
                              value: weather.seeingScore?.toString() ?? 'N/A',
                              subValue: weather.seeingLabel ?? 'Unknown',
                              subValueColor: seeingColor,
                              progress: ((weather.seeingScore ?? 0) / 10.0).clamp(0.0, 1.0),
                              progressColor: seeingColor,
                            ),
                            // Darkness
                            darknessAsync.when(
                              data: (darkness) => _buildMetricCard(
                                icon: Ionicons.moon_outline,
                                label: 'Darkness',
                                value: darkness.mpsas.toStringAsFixed(1),
                                subValue: darkness.label,
                                subValueColor: Color(darkness.color),
                                progress: ((darkness.mpsas - 17.0) / (22.0 - 17.0)).clamp(0.0, 1.0), // Normalize 17-22 to 0-1
                                progressColor: Color(darkness.color),
                              ),
                              loading: () => _buildMetricCard(
                                icon: Ionicons.moon_outline,
                                label: 'Darkness',
                                value: '...',
                                subValue: 'Calculating...',
                              ),
                              error: (_, __) => _buildMetricCard(
                                icon: Ionicons.moon_outline,
                                label: 'Darkness',
                                value: 'N/A',
                                subValue: 'Error',
                                subValueColor: Colors.red,
                              ),
                            ),
                            // Humidity
                            _buildMetricCard(
                              icon: Ionicons.water_outline,
                              label: 'Humidity',
                              value: weather.humidity != null ? '${weather.humidity!.round()}%' : 'N/A',
                              iconColor: Colors.cyanAccent,
                            ),
                            // Temperature
                            _buildMetricCard(
                              icon: Ionicons.thermometer_outline,
                              label: 'Temp',
                              value: weather.temperatureC != null ? '${weather.temperatureC!.round()}°C' : 'N/A',
                              iconColor: Colors.orangeAccent,
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Fixed Header with Blur
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0B).withValues(alpha: 0.7),
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Atmospherics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    ref.read(weatherProvider.notifier).refresh();
                                  },
                                  icon: const Icon(Ionicons.refresh_circle, color: Colors.white54, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Ionicons.close_circle, color: Colors.white54, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current viewing conditions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    Color? subValueColor,
    Color? iconColor,
    double? progress,
    Color? progressColor,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: iconColor ?? Colors.white, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (subValue != null)
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subValueColor ?? Colors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          if (progress != null)
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
