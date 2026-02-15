import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/engine/prime_view_calculator.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../catalog/domain/entities/celestial_object.dart';
import '../../../catalog/domain/entities/graph_point.dart';
import '../../../catalog/presentation/providers/object_detail_notifier.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import '../../../catalog/presentation/providers/visibility_graph_notifier.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../../domain/entities/weather.dart';
import '../providers/darkness_provider.dart';
import '../providers/night_window_provider.dart';
import '../providers/prime_view_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/graph_theme.dart';
import 'conditions_graph.dart';
import 'graph_legend_item.dart';
import 'hourly_forecast_list.dart';
import 'time_card.dart';

class AtmosphericsSheet extends ConsumerWidget {
  const AtmosphericsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
    final AsyncValue<DarknessState> darknessAsync = ref.watch(darknessProvider);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

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
          children: <Widget>[
            // 1. Background (Fixed)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  // Story 4.4: Pure OLED black for NFR-09
                  color: const Color(0xFF000000),
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
                  children: <Widget>[
                    // Legend
                    const Row(
                      children: <Widget>[
                        GraphLegendItem(label: 'MOON', color: GraphTheme.moonColor),
                        SizedBox(width: 12),
                        GraphLegendItem(label: 'CLOUD COVER', color: GraphTheme.cloudCoverColor),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Conditions Graph
                    // Conditions Graph
                    Consumer(
                      builder: (BuildContext context, WidgetRef ref, Widget? child) {
                        final AsyncValue<Map<String, DateTime>> nightWindowAsync = ref.watch(nightWindowProvider);
                        
                        return nightWindowAsync.when(
                          data: (Map<String, DateTime> nightWindow) {
                            final DateTime startTime = nightWindow['start']!;
                            final DateTime endTime = nightWindow['end']!;

                            final ObjectDetailState moonState = ref.watch(objectDetailNotifierProvider('moon'));
                            final CelestialObject? moon = moonState.object;
                            
                            DateTime? moonRise;
                            if (moon != null) {
                                final AsyncValue<Map<String, DateTime?>> riseSetAsync = ref.watch(riseSetProvider(moon));
                                final Map<String, DateTime?>? times = riseSetAsync.valueOrNull;
                                if (times != null && times['rise'] != null) {
                                    moonRise = times['rise'];
                                }
                            }

                            // Fetch Moon Graph Data for the curve
                            final VisibilityGraphState moonGraphState = ref.watch(visibilityGraphProvider('moon'));
                            final List<GraphPoint>? moonCurve = moonGraphState.graphData?.objectCurve;

                            // Fetch Cloud Cover Data
                            final AsyncValue<List<HourlyForecast>> hourlyForecastAsync = ref.watch(hourlyForecastProvider);
                            final List<HourlyForecast>? cloudCoverData = hourlyForecastAsync.valueOrNull;

                            // Fetch Prime View Window
                            final AsyncValue<PrimeViewWindow?> primeViewAsync = ref.watch(primeViewProvider);
                            final PrimeViewWindow? primeViewWindow = primeViewAsync.valueOrNull;

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
                                  padding: const EdgeInsets.all(16),
                                  child: ConditionsGraph(
                                      startTime: startTime,
                                      endTime: endTime,
                                      moonRiseTime: moonRise,
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
                          error: (Object err, StackTrace stack) => SizedBox(
                            height: 200,
                            child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                          ),
                        );
                      }
                    ),

                    // Rise/Set Cards
                    Consumer(
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            children: <Widget>[
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
                      data: (Weather weather) {
                        // Seeing Color Logic (Red Mode compatible - Epic 5)
                        // Using theme-neutral colors that can be filtered by Red Mode
                        Color seeingColor = Colors.white;
                        if (weather.seeingScore != null) {
                          if (weather.seeingScore! >= 8) {
                            // Excellent - use light green tone
                            seeingColor = const Color(0xFF90EE90);
                          } else if (weather.seeingScore! >= 5) {
                            // Good - use amber tone
                            seeingColor = const Color(0xFFFFA500);
                          } else {
                            // Poor - use muted tone
                            seeingColor = Colors.white.withValues(alpha: 0.6);
                          }
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: <Widget>[
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
                              data: (DarknessState darkness) => _buildMetricCard(
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
                      error: (Object err, StackTrace stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    ),

                    // Story 4.4: Hourly Forecast List (AC4)
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (BuildContext context, WidgetRef ref, Widget? child) {
                        final AsyncValue<List<HourlyForecast>> hourlyForecastAsync = ref.watch(hourlyForecastProvider);
                        
                        return hourlyForecastAsync.when(
                          data: (List<HourlyForecast> forecasts) => HourlyForecastList(forecasts: forecasts),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (Object _, StackTrace __) => const SizedBox.shrink(),
                        );
                      },
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
                      // Story 4.4: Pure OLED black for header (NFR-09)
                    color: const Color(0xFF000000),
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
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
                              children: <Widget>[
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
                            color: Colors.white.withValues(alpha: 0.5),
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
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1,
                ),
              ),
              Icon(icon, color: iconColor ?? Colors.white, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
