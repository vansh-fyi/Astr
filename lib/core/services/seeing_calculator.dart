/// SeeingCalculator Service - AC#2, AC#4
/// Calculates atmospheric seeing quality using Pickering Scale (1-10) heuristic
/// 
/// **AC#2: Heuristic Calculation Model**
/// The true Pickering scale is observational (astronomer visually assesses star diffraction
/// pattern through telescope). This implementation uses meteorological data as a proxy.
/// 
/// **AC#4: Algorithm Logic**
/// - Base Score: Start at 10 (perfect seeing)
/// - Temperature Gradient Penalty:
///   * variance > 5°C over 3 hours: -2 points (high turbulence)
///   * variance > 3°C over 3 hours: -1 point (moderate turbulence)
/// - Wind Speed Penalty:
///   * wind > 30 km/h: -3 points (severe atmospheric mixing)
///   * wind > 20 km/h: -2 points
///   * wind > 10 km/h: -1 point
/// - Humidity Bonus:
///   * humidity > 70% with stable temp (<3°C variance): +1 point (stable air mass)
/// - Final Score: Clamp to 1-10 range
/// 
/// **Research Citations:**
/// - Pickering, William H. (Harvard College Observatory) - Original seeing scale definition
/// - "Atmospheric Seeing" - Wikipedia (https://en.wikipedia.org/wiki/Astronomical_seeing)
/// - Atmospheric turbulence factors: Temperature gradients, wind shear, humidity
///   (Sources: SPIE, astrobackyard.com)
library;

class SeeingCalculator {
  /// Calculates Pickering Seeing score (1-10) from hourly weather data
  /// 
  /// AC#4: Input requires at least 3 hours of data for temperature variance calculation
  /// Returns tuple: (score, label)
  /// 
  /// Labels (AC#1):
  /// - 1-2: "Extremely Poor"
  /// - 3-4: "Poor"
  /// - 5-6: "Fair"
  /// - 7-8: "Good"
  /// - 9-10: "Excellent"
  (int, String) calculateSeeing({
    required List<double> temperatures, // Hourly temperatures in °C (AC#3)
    required List<double> windSpeeds,   // Hourly wind speeds in km/h (AC#3)
    required List<double> humidities,   // Hourly humidity percentages (AC#3)
  }) {
    // Validate input data
    if (temperatures.isEmpty || windSpeeds.isEmpty || humidities.isEmpty) {
      return (5, 'Fair'); // Default to middle score if no data
    }

    // Use current hour (index 0) for instant calculations
    final double currentWind = windSpeeds[0];
    final double currentHumidity = humidities[0];

    // Calculate temperature variance over 3 hours (AC#4)
    final double tempVariance = _calculateTemperatureVariance(temperatures);

    // AC#4: Start with base score (perfect seeing)
    int score = 10;

    // AC#4: Temperature Gradient Penalty
    if (tempVariance > 5.0) {
      score -= 2; // High turbulence
    } else if (tempVariance > 3.0) {
      score -= 1; // Moderate turbulence
    }

    // AC#4: Wind Speed Penalty
    if (currentWind > 30.0) {
      score -= 3; // Severe atmospheric mixing
    } else if (currentWind > 20.0) {
      score -= 2;
    } else if (currentWind > 10.0) {
      score -= 1;
    }

    // AC#4: Humidity Bonus (stable air mass)
    if (currentHumidity > 70.0 && tempVariance < 3.0) {
      score += 1;
    }

    // AC#4: Clamp final score to 1-10 range
    score = score.clamp(1, 10);

    // AC#1: Map score to descriptive label
    final String label = _getSeeingLabel(score);

    return (score, label);
  }

  /// Calculates temperature variance over 3-hour window
  /// Returns maximum temperature difference in °C
  double _calculateTemperatureVariance(List<double> temperatures) {
    if (temperatures.length < 3) {
      // Not enough data for 3-hour window, use available data
      if (temperatures.length == 1) return 0;
      return (temperatures.reduce((double a, double b) => a > b ? a : b) - 
              temperatures.reduce((double a, double b) => a < b ? a : b)).abs();
    }

    // Use first 3 hours (indices 0, 1, 2)
    final List<double> threeHourData = temperatures.take(3).toList();
    final double maxTemp = threeHourData.reduce((double a, double b) => a > b ? a : b);
    final double minTemp = threeHourData.reduce((double a, double b) => a < b ? a : b);
    
    return (maxTemp - minTemp).abs();
  }

  /// Maps Pickering score to descriptive label (AC#1)
  String _getSeeingLabel(int score) {
    if (score >= 9) return 'Excellent';  // 9-10
    if (score >= 7) return 'Good';       // 7-8
    if (score >= 5) return 'Fair';       // 5-6
    if (score >= 3) return 'Poor';       // 3-4
    return 'Extremely Poor';              // 1-2
  }
}
