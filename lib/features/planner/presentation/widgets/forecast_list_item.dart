import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';

class ForecastListItem extends StatelessWidget {
  final DailyForecast forecast;

  const ForecastListItem({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final dateStr = dateFormat.format(forecast.date);

    return GlassPanel(
      enableBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          
          // Weather Icon
          Expanded(
            flex: 2,
            child: Icon(
              _getWeatherIcon(forecast.weatherCode),
              color: Colors.white70,
              size: 24,
            ),
          ),
          
          // Cloud Cover
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Ionicons.cloud_outline, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  '${forecast.cloudCoverAvg.round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          
          // Star Rating
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return Icon(
                  index < forecast.starRating ? Ionicons.star : Ionicons.star_outline,
                  size: 16,
                  color: index < forecast.starRating ? const Color(0xFFFFD700) : Colors.white24,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    // WMO Weather interpretation codes (WW)
    if (code == 0) return Ionicons.sunny;
    if (code >= 1 && code <= 3) return Ionicons.partly_sunny;
    if (code == 45 || code == 48) return Ionicons.cloudy;
    if (code >= 51 && code <= 67) return Ionicons.rainy;
    if (code >= 71 && code <= 77) return Ionicons.snow;
    if (code >= 80 && code <= 82) return Ionicons.rainy;
    if (code >= 95 && code <= 99) return Ionicons.thunderstorm;
    return Ionicons.cloud_outline;
  }
}
