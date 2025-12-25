import '../../../astronomy/domain/entities/celestial_body.dart';
import '../../../astronomy/domain/entities/celestial_position.dart';
import '../entities/highlight_item.dart';

class HighlightsLogic {
  /// Selects the top 3 highlights from a list of celestial positions.
  ///
  /// Logic:
  /// 1. Filter objects with Altitude > 10 degrees.
  /// 2. Exclude the Sun (as it's not a stargazing target).
  /// 3. Sort by Magnitude (ascending, lower is brighter).
  /// 4. Take the top 3.
  static List<HighlightItem> selectTop3({
    required List<CelestialPosition> positions,
  }) {
    // 0. Determine if it's "Daytime" (Sun Altitude > -6 degrees, i.e., Civil Twilight)
    double sunAltitude = -90;
    try {
      final CelestialPosition sunPos = positions.firstWhere((CelestialPosition p) => p.body == CelestialBody.sun);
      sunAltitude = sunPos.altitude;
    } catch (e) {
      // Sun not found in list, assume night or handle gracefully
    }

    final bool isDaytime = sunAltitude > -6.0;

    // 1. Filter visible objects
    final List<CelestialPosition> visibleObjects = positions.where((CelestialPosition pos) {
      // Ensure body is not null
      if (pos.body == null) return false;

      // Always exclude Sun from highlights
      if (pos.body == CelestialBody.sun) return false;

      // Basic visibility check (above horizon + buffer)
      if (pos.altitude <= 10.0) return false;

      // Daytime Logic:
      // If it's daytime, ONLY the Moon is visible.
      // Planets/Stars are washed out by the Sun.
      if (isDaytime) {
        return pos.body == CelestialBody.moon;
      }

      return true;
    }).toList();

    // 2. Sort by Magnitude (ascending)
    // Note: For MVP, we treat all remaining bodies (Moon, Planets) as high priority.
    // We sort purely by brightness.
    visibleObjects.sort((CelestialPosition a, CelestialPosition b) => a.magnitude.compareTo(b.magnitude));

    // 3. Take Top 3
    final List<CelestialPosition> top3 = visibleObjects.take(3).toList();

    // 4. Map to HighlightItem
    return top3.map((CelestialPosition pos) => HighlightItem(
      body: pos.body!,
      altitude: pos.altitude,
      magnitude: pos.magnitude,
      isVisible: true,
    )).toList();
  }
}
