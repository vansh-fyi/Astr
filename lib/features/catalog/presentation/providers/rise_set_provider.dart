import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:sweph/sweph.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/utils/timezone_helper.dart';
import '../../../astronomy/domain/services/astronomy_service.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/graph_point.dart';

/// Provides the selected location's UTC offset label (e.g., "UTC+0", "UTC+5:30").
///
/// Always reflects the location's timezone (including DST), regardless of
/// whether rise/set times were successfully computed.
final Provider<String> locationOffsetLabelProvider = Provider<String>((ProviderRef<String> ref) {
  final AsyncValue<AstrContext> contextState = ref.watch(astrContextProvider);
  if (!contextState.hasValue) return 'UTC${TimezoneHelper.deviceOffsetLabel}';

  final AstrContext ctx = contextState.value!;
  final String tzName = tzmap.latLngToTimezoneString(
    ctx.location.latitude,
    ctx.location.longitude,
  );
  final tz.Location location = tz.getLocation(tzName);
  final tz.TZDateTime now = tz.TZDateTime.now(location);
  return 'UTC${TimezoneHelper.formatOffset(now.timeZoneOffset)}';
});

final FutureProviderFamily<Map<String, DateTime?>, CelestialObject> riseSetProvider = FutureProvider.family<Map<String, DateTime?>, CelestialObject>((FutureProviderRef<Map<String, DateTime?>> ref, CelestialObject object) async {
  final AstronomyService astronomyService = ref.watch(astronomyServiceProvider);
  final AsyncValue<AstrContext> contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
  }
  
  final AstrContext astrContext = contextState.value!;
  
  // First, try to map to HeavenlyBody for planets/sun/moon ONLY
  // (Stars use trajectory-based path for consistency with visibility graph)
  final HeavenlyBody? body = _mapToHeavenlyBody(object);
  
  if (body != null) {
    // Use sweph for planets, sun, moon
    try {
      return await astronomyService.calculateRiseSetTransit(
        body: body,
        date: astrContext.selectedDate,
        lat: astrContext.location.latitude,
        long: astrContext.location.longitude,
      );
    } catch (e) {
      return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
    }
  }
  
  // For Stars, DSOs (galaxies, nebulae, clusters), and Constellations
  // Use trajectory-based calculation for consistency with visibility graph
  if (object.ra != null && object.dec != null) {
    try {
      // Get the night window (sunset to sunrise)
      final Map<String, DateTime> nightWindow = await astronomyService.getNightWindow(
        date: astrContext.selectedDate,
        lat: astrContext.location.latitude,
        long: astrContext.location.longitude,
      );
      
      final DateTime nightStart = nightWindow['start']!;
      final DateTime nightEnd = nightWindow['end']!;
      
      // FIXED: Extend scan window to start 12 hours BEFORE sunset
      // This ensures we capture rise/set events for objects that are already up
      final DateTime scanStart = nightStart.subtract(const Duration(hours: 12));
      
      // Calculate trajectory from 12 hours before sunset to sunrise (covering ~24h)
      final List<GraphPoint> trajectory = await astronomyService.calculateFixedObjectTrajectory(
        ra: object.ra!,
        dec: object.dec!,
        startTime: scanStart,
        lat: astrContext.location.latitude,
        long: astrContext.location.longitude,
        duration: const Duration(hours: 24),
      );
      
      if (trajectory.isEmpty) {
        return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
      }
      
      // Check for circumpolar (always above horizon) or never visible
      final double minAlt = trajectory.map((GraphPoint p) => p.value).reduce((double a, double b) => a < b ? a : b);
      final double maxAlt = trajectory.map((GraphPoint p) => p.value).reduce((double a, double b) => a > b ? a : b);
      
      if (minAlt > 0) {
        // Object is circumpolar - never sets, find transit only
        DateTime? transitTime;
        double maxNightAlt = -90;
        for (final GraphPoint point in trajectory) {
          // Only consider transit within the night window
          if (point.time.isAfter(nightStart) && point.time.isBefore(nightEnd)) {
            if (point.value > maxNightAlt) {
              maxNightAlt = point.value;
              transitTime = point.time;
            }
          }
        }
        return <String, DateTime?>{'rise': null, 'set': null, 'transit': transitTime};
      }
      
      if (maxAlt < 0) {
        // Object never rises
        return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
      }
      
      // Find ALL rise and set events in the trajectory
      final List<DateTime> riseEvents = <DateTime>[];
      final List<DateTime> setEvents = <DateTime>[];
      
      for (int i = 1; i < trajectory.length; i++) {
        final GraphPoint prev = trajectory[i - 1];
        final GraphPoint curr = trajectory[i];
        
        // Detect rise (altitude crosses from below 0 to above 0)
        if (prev.value <= 0 && curr.value > 0) {
          final double fraction = -prev.value / (curr.value - prev.value);
          final Duration riseOffset = Duration(
            milliseconds: (fraction * curr.time.difference(prev.time).inMilliseconds).round(),
          );
          riseEvents.add(prev.time.add(riseOffset));
        }
        
        // Detect set (altitude crosses from above 0 to below 0)
        if (prev.value > 0 && curr.value <= 0) {
          final double fraction = prev.value / (prev.value - curr.value);
          final Duration setOffset = Duration(
            milliseconds: (fraction * curr.time.difference(prev.time).inMilliseconds).round(),
          );
          setEvents.add(prev.time.add(setOffset));
        }
      }
      
      // Check if object is visible at sunset (start of night window)
      bool visibleAtSunset = false;
      for (final GraphPoint point in trajectory) {
        if (point.time.difference(nightStart).inMinutes.abs() < 20) {
          visibleAtSunset = point.value > 0;
          break;
        }
      }
      
      // Find the relevant rise time: 
      // - If not visible at sunset, find first rise AFTER sunset
      // - If visible at sunset, find the rise that happened BEFORE sunset (most recent)
      DateTime? riseTime;
      if (!visibleAtSunset) {
        // Find first rise after sunset
        for (final DateTime rise in riseEvents) {
          if (rise.isAfter(nightStart) || rise.isAtSameMomentAs(nightStart)) {
            riseTime = rise;
            break;
          }
        }
      } else {
        // Object already up - find the most recent rise before sunset
        for (final DateTime rise in riseEvents.reversed) {
          if (rise.isBefore(nightStart)) {
            riseTime = rise;
            break;
          }
        }
      }
      
      // Find set time: first set event AFTER nightStart
      DateTime? setTime;
      for (final DateTime set in setEvents) {
        if (set.isAfter(nightStart)) {
          setTime = set;
          break;
        }
      }
      
      // Find transit: highest point WITHIN the night window only
      DateTime? transitTime;
      double maxNightAlt = -90;
      for (final GraphPoint point in trajectory) {
        if (point.time.isAfter(nightStart) && point.time.isBefore(nightEnd)) {
          if (point.value > maxNightAlt) {
            maxNightAlt = point.value;
            transitTime = point.time;
          }
        }
      }
      
      return <String, DateTime?>{
        'rise': riseTime,
        'set': setTime,
        'transit': transitTime,
      };
    } catch (e) {
      return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
    }
  }
  
  return <String, DateTime?>{'rise': null, 'set': null, 'transit': null};
});

/// Maps only planets, sun, and moon to HeavenlyBody.
/// Stars, DSOs, and constellations should NOT be mapped here - 
/// they use the trajectory-based calculation instead.
HeavenlyBody? _mapToHeavenlyBody(CelestialObject object) {
  final String name = object.name.toLowerCase();
  switch (name) {
    case 'sun': return HeavenlyBody.SE_SUN;
    case 'moon': return HeavenlyBody.SE_MOON;
    case 'mercury': return HeavenlyBody.SE_MERCURY;
    case 'venus': return HeavenlyBody.SE_VENUS;
    case 'mars': return HeavenlyBody.SE_MARS;
    case 'jupiter': return HeavenlyBody.SE_JUPITER;
    case 'saturn': return HeavenlyBody.SE_SATURN;
    case 'uranus': return HeavenlyBody.SE_URANUS;
    case 'neptune': return HeavenlyBody.SE_NEPTUNE;
    case 'pluto': return HeavenlyBody.SE_PLUTO;
    default:
      // Stars, DSOs, and constellations use trajectory-based path
      return null;
  }
}


