import 'package:astr/core/engine/algorithms/rise_set_calculator.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweph/sweph.dart';

final riseSetProvider = FutureProvider.family<Map<String, DateTime?>, CelestialObject>((ref, object) async {
  final astronomyService = ref.watch(astronomyServiceProvider);
  final contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    return {'rise': null, 'set': null, 'transit': null};
  }
  
  final astrContext = contextState.value!;
  
  // First, try to map to HeavenlyBody for planets/sun/moon ONLY
  // (Stars use trajectory-based path for consistency with visibility graph)
  final body = _mapToHeavenlyBody(object);
  
  if (body != null) {
    // Use sweph for planets, sun, moon
    try {
      return await astronomyService.calculateRiseSetTransit(
        body: body,
        date: astrContext.selectedDate,
        lat: astrContext.location!.latitude,
        long: astrContext.location!.longitude,
      );
    } catch (e) {
      return {'rise': null, 'set': null, 'transit': null};
    }
  }
  
  // For Stars, DSOs (galaxies, nebulae, clusters), and Constellations
  // Use trajectory-based calculation for consistency with visibility graph
  if (object.ra != null && object.dec != null) {
    try {
      // Get the night window (sunset to sunrise)
      final nightWindow = await astronomyService.getNightWindow(
        date: astrContext.selectedDate,
        lat: astrContext.location!.latitude,
        long: astrContext.location!.longitude,
      );
      
      final nightStart = nightWindow['start']!;
      final nightEnd = nightWindow['end']!;
      
      // FIXED: Extend scan window to start 12 hours BEFORE sunset
      // This ensures we capture rise/set events for objects that are already up
      final scanStart = nightStart.subtract(const Duration(hours: 12));
      
      // Calculate trajectory from 12 hours before sunset to sunrise (covering ~24h)
      final trajectory = await astronomyService.calculateFixedObjectTrajectory(
        ra: object.ra!,
        dec: object.dec!,
        startTime: scanStart,
        lat: astrContext.location!.latitude,
        long: astrContext.location!.longitude,
        duration: const Duration(hours: 24),
      );
      
      if (trajectory.isEmpty) {
        return {'rise': null, 'set': null, 'transit': null};
      }
      
      // Check for circumpolar (always above horizon) or never visible
      final minAlt = trajectory.map((p) => p.value).reduce((a, b) => a < b ? a : b);
      final maxAlt = trajectory.map((p) => p.value).reduce((a, b) => a > b ? a : b);
      
      if (minAlt > 0) {
        // Object is circumpolar - never sets, find transit only
        DateTime? transitTime;
        double maxNightAlt = -90;
        for (final point in trajectory) {
          // Only consider transit within the night window
          if (point.time.isAfter(nightStart) && point.time.isBefore(nightEnd)) {
            if (point.value > maxNightAlt) {
              maxNightAlt = point.value;
              transitTime = point.time;
            }
          }
        }
        return {'rise': null, 'set': null, 'transit': transitTime};
      }
      
      if (maxAlt < 0) {
        // Object never rises
        return {'rise': null, 'set': null, 'transit': null};
      }
      
      // Find ALL rise and set events in the trajectory
      final List<DateTime> riseEvents = [];
      final List<DateTime> setEvents = [];
      
      for (int i = 1; i < trajectory.length; i++) {
        final prev = trajectory[i - 1];
        final curr = trajectory[i];
        
        // Detect rise (altitude crosses from below 0 to above 0)
        if (prev.value <= 0 && curr.value > 0) {
          final fraction = -prev.value / (curr.value - prev.value);
          final riseOffset = Duration(
            milliseconds: (fraction * curr.time.difference(prev.time).inMilliseconds).round(),
          );
          riseEvents.add(prev.time.add(riseOffset));
        }
        
        // Detect set (altitude crosses from above 0 to below 0)
        if (prev.value > 0 && curr.value <= 0) {
          final fraction = prev.value / (prev.value - curr.value);
          final setOffset = Duration(
            milliseconds: (fraction * curr.time.difference(prev.time).inMilliseconds).round(),
          );
          setEvents.add(prev.time.add(setOffset));
        }
      }
      
      // Check if object is visible at sunset (start of night window)
      bool visibleAtSunset = false;
      for (final point in trajectory) {
        if ((point.time.difference(nightStart).inMinutes).abs() < 20) {
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
        for (final rise in riseEvents) {
          if (rise.isAfter(nightStart) || rise.isAtSameMomentAs(nightStart)) {
            riseTime = rise;
            break;
          }
        }
      } else {
        // Object already up - find the most recent rise before sunset
        for (final rise in riseEvents.reversed) {
          if (rise.isBefore(nightStart)) {
            riseTime = rise;
            break;
          }
        }
      }
      
      // Find set time: first set event AFTER nightStart
      DateTime? setTime;
      for (final set in setEvents) {
        if (set.isAfter(nightStart)) {
          setTime = set;
          break;
        }
      }
      
      // Find transit: highest point WITHIN the night window only
      DateTime? transitTime;
      double maxNightAlt = -90;
      for (final point in trajectory) {
        if (point.time.isAfter(nightStart) && point.time.isBefore(nightEnd)) {
          if (point.value > maxNightAlt) {
            maxNightAlt = point.value;
            transitTime = point.time;
          }
        }
      }
      
      return {
        'rise': riseTime,
        'set': setTime,
        'transit': transitTime,
      };
    } catch (e) {
      return {'rise': null, 'set': null, 'transit': null};
    }
  }
  
  return {'rise': null, 'set': null, 'transit': null};
});

/// Maps only planets, sun, and moon to HeavenlyBody.
/// Stars, DSOs, and constellations should NOT be mapped here - 
/// they use the trajectory-based calculation instead.
HeavenlyBody? _mapToHeavenlyBody(CelestialObject object) {
  final name = object.name.toLowerCase();
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


