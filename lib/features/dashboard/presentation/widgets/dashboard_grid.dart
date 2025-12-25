import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../../astronomy/domain/entities/moon_phase_info.dart';
import '../../../catalog/domain/entities/celestial_object.dart';
import '../../../catalog/presentation/providers/object_detail_notifier.dart';
import '../../../catalog/presentation/providers/rise_set_provider.dart';
import '../../domain/entities/hourly_forecast.dart';
import '../../domain/entities/light_pollution.dart';
import '../providers/weather_provider.dart';
import 'atmospherics_sheet.dart';
import 'bortle_bar.dart';
import 'celestial_detail_sheet.dart';
import 'cloud_bar.dart';
import 'time_card.dart';

class DashboardGrid extends ConsumerStatefulWidget {

  const DashboardGrid({
    super.key,
    required this.cloudCover,
    required this.lightPollution,
    required this.moonPhaseInfo,
  });
  final double cloudCover;
  final LightPollution lightPollution;
  final MoonPhaseInfo moonPhaseInfo;

  @override
  ConsumerState<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends ConsumerState<DashboardGrid> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Reset every 20 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 20), (Timer timer) {
      ref.invalidate(hourlyForecastProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch hourly forecast for mean calculation
    final AsyncValue<List<HourlyForecast>> hourlyForecastAsync = ref.watch(hourlyForecastProvider);
    
    double displayedCloudCover = widget.cloudCover;

    if (hourlyForecastAsync.hasValue) {
      final List<HourlyForecast> forecasts = hourlyForecastAsync.value!;
      final DateTime now = DateTime.now();
      final DateTime threeHoursLater = now.add(const Duration(hours: 3));
      
      final List<HourlyForecast> relevantForecasts = forecasts.where((HourlyForecast f) => 
        f.time.isAfter(now.subtract(const Duration(minutes: 30))) && 
        f.time.isBefore(threeHoursLater)
      ).toList();

      if (relevantForecasts.isNotEmpty) {
        final double totalCloudCover = relevantForecasts.fold(0, (double sum, HourlyForecast f) => sum + f.cloudCover);
        displayedCloudCover = totalCloudCover / relevantForecasts.length;
      }
    }

    return Column(
      children: <Widget>[
        // Main Forecast Strip
        GlassPanel(
          enableBlur: false,
          padding: const EdgeInsets.all(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (BuildContext context) => const AtmosphericsSheet(),
            );
          },
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Clear Skies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Perfect visibility for observation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Ionicons.cloud_offline_outline,
                    color: Colors.indigo[300],
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cloud Bar (Replaces manual progress bar)
              CloudBar(cloudCoverPercentage: displayedCloudCover),
              
              const SizedBox(height: 16),

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

                  return Row(
                    children: <Widget>[
                      Expanded(child: TimeCard(label: 'SUNRISE', time: sunRise)),
                      const SizedBox(width: 8),
                      Expanded(child: TimeCard(label: 'SUNSET', time: sunSet)),
                      const SizedBox(width: 8),
                      Expanded(child: TimeCard(label: 'MOONRISE', time: moonRise)),
                      const SizedBox(width: 8),
                      Expanded(child: TimeCard(label: 'MOONSET', time: moonSet)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Two Column Grid
        Row(
          children: <Widget>[
            // Bortle Card
            Expanded(
              child: BortleBar(
                lightPollution: widget.lightPollution,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (BuildContext context) => const AtmosphericsSheet(),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Moon Card
            Expanded(
              child: GlassPanel(
                enableBlur: false,
                padding: const EdgeInsets.all(20),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (BuildContext context) => CelestialDetailSheet(
                      objectId: 'moon',
                      title: 'Moon',
                      subtitle: _getMoonPhaseLabel(widget.moonPhaseInfo),
                      themeColor: Colors.blueAccent,
                    ),
                  );
                },
                child: SizedBox(
                  height: 150, // Match BortleBar fixed height
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'MOON',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${(widget.moonPhaseInfo.illumination * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      
                      // Moon Phase Image
                      // AC#2: Increased from 64 to 80 to compensate for padding
                      Image.asset(
                        _getMoonAsset(widget.moonPhaseInfo),
                        width: 104,
                        height: 104,
                      ),

                      Text(
                        _getMoonPhaseLabel(widget.moonPhaseInfo),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  String _getMoonAsset(MoonPhaseInfo info) {
    // Phase Angle (0-360)
    // 0 = New Moon
    // 90 = First Quarter
    // 180 = Full Moon
    // 270 = Last Quarter

    final double angle = info.phaseAngle;

    // New Moon (0 +/- 5)
    if (angle >= 355 || angle <= 5) return 'assets/img/moon_new.webp';

    // Waxing Crescent (5 - 85)
    if (angle > 5 && angle < 85) return 'assets/img/moon_waxing_crescent.webp';

    // First Quarter (90 +/- 5)
    if (angle >= 85 && angle <= 95) return 'assets/img/moon_first_quarter.webp';

    // Waxing Gibbous (95 - 175)
    if (angle > 95 && angle < 175) return 'assets/img/moon_waxing_gibbous.webp';

    // Full Moon (180 +/- 5)
    if (angle >= 175 && angle <= 185) return 'assets/img/moon_full.webp';

    // Waning Gibbous (185 - 265)
    if (angle > 185 && angle < 265) return 'assets/img/moon_waning_gibbous.webp';

    // Last Quarter (270 +/- 5)
    if (angle >= 265 && angle <= 275) return 'assets/img/moon_last_quarter.webp';

    // Waning Crescent (275 - 355)
    if (angle > 275 && angle < 355) return 'assets/img/moon_waning_crescent.webp';

    return 'assets/img/moon_waning_gibbous.webp'; // Fallback
  }

  String _getMoonPhaseLabel(MoonPhaseInfo info) {
    final double angle = info.phaseAngle;
    
    if (angle >= 355 || angle <= 5) return 'New Moon';
    if (angle > 5 && angle < 85) return 'Waxing Crescent';
    if (angle >= 85 && angle <= 95) return 'First Quarter';
    if (angle > 95 && angle < 175) return 'Waxing Gibbous';
    if (angle >= 175 && angle <= 185) return 'Full Moon';
    if (angle > 185 && angle < 265) return 'Waning Gibbous';
    if (angle >= 265 && angle <= 275) return 'Last Quarter';
    if (angle > 275 && angle < 355) return 'Waning Crescent';
    
    return 'Moon';
  }
}
