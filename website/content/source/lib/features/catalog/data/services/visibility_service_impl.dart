import 'package:fpdart/fpdart.dart';
import 'package:sweph/sweph.dart';

import '../../../../core/error/failure.dart';
import '../../../astronomy/domain/services/astronomy_service.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/celestial_type.dart';
import '../../domain/entities/graph_point.dart';
import '../../domain/entities/time_range.dart';
import '../../domain/entities/visibility_graph_data.dart';
import '../../domain/services/i_visibility_service.dart';

/// Implementation of visibility service for calculating visibility graph data
class VisibilityServiceImpl implements IVisibilityService {

  const VisibilityServiceImpl(this._astronomyService);
  final AstronomyService _astronomyService;

  @override
  Future<Either<Failure, VisibilityGraphData>> calculateVisibility({
    required CelestialObject object,
    required GeoLocation location,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    try {
      final Duration duration = endTime != null 
          ? endTime.difference(startTime) 
          : const Duration(hours: 12);

      // 1. Calculate Object Trajectory
      List<GraphPoint> objectCurve;
      
      // Check for Ephemeris ID first (Planets, Sun, Moon)
      if (object.ephemerisId != null) {
        final HeavenlyBody? body = _mapToHeavenlyBody(object);
        if (body != null) {
        objectCurve = await _astronomyService.calculateAltitudeTrajectory(
            body: body,
            startTime: startTime,
            lat: location.latitude,
            long: location.longitude,
            duration: duration,
          );
        } else {
           return Left(CalculationFailure('Failed to map object with ephemerisId to HeavenlyBody: ${object.name}'));
        }
      } 
      // Check for RA/Dec (Stars, DSOs)
      else if (object.ra != null && object.dec != null) {
        objectCurve = await _astronomyService.calculateFixedObjectTrajectory(
          ra: object.ra!,
          dec: object.dec!,
          startTime: startTime,
          lat: location.latitude,
          long: location.longitude,
          duration: duration,
        );
      } else {
        return Left(CalculationFailure('Unsupported celestial object: ${object.name} (No Ephemeris ID or RA/Dec)'));
      }

      // 2. Calculate Moon Trajectory
      final List<GraphPoint> moonCurve = await _astronomyService.calculateMoonTrajectory(
        startTime: startTime,
        lat: location.latitude,
        long: location.longitude,
        duration: duration,
      );

      // 3. Calculate Optimal Windows
      // Logic: Object Altitude > 30 AND Moon Interference < 30 (arbitrary threshold, maybe 10?)
      // Let's use 30 for now as per previous mock logic.
      const double minObjectAltitude = 30;
      const double maxMoonInterference = 30;
      final List<TimeRange> optimalRanges = <TimeRange>[];
      DateTime? windowStart;

      for (int i = 0; i < objectCurve.length; i++) {
        final GraphPoint objectPoint = objectCurve[i];
        // Ensure we have a matching moon point (should be same length)
        final GraphPoint moonPoint = i < moonCurve.length ? moonCurve[i] : GraphPoint(time: objectPoint.time, value: 0);
        
        final double objectAlt = objectPoint.value;
        final double moonInterference = moonPoint.value;

        final bool isOptimal = objectAlt > minObjectAltitude && moonInterference < maxMoonInterference;

        if (isOptimal && windowStart == null) {
          windowStart = objectPoint.time;
        } else if (!isOptimal && windowStart != null) {
          optimalRanges.add(TimeRange(start: windowStart, end: objectPoint.time));
          windowStart = null;
        }
      }

      // Close open window
      if (windowStart != null) {
        optimalRanges.add(TimeRange(start: windowStart, end: objectCurve.last.time));
      }

      // 4. Calculate Sun/Moon Rise/Set Times
      final Map<String, DateTime?> sunTimes = await _astronomyService.calculateRiseSetTransit(
        body: HeavenlyBody.SE_SUN,
        date: startTime,
        lat: location.latitude,
        long: location.longitude,
      );
      
      final Map<String, DateTime?> moonTimes = await _astronomyService.calculateRiseSetTransit(
        body: HeavenlyBody.SE_MOON,
        date: startTime,
        lat: location.latitude,
        long: location.longitude,
      );

      return Right(VisibilityGraphData(
        objectCurve: objectCurve,
        moonCurve: moonCurve,
        optimalWindows: optimalRanges,
        sunRise: sunTimes['rise'],
        sunSet: sunTimes['set'],
        moonRise: moonTimes['rise'],
        moonSet: moonTimes['set'],
      ));
    } catch (e) {
      return Left(CalculationFailure('Error calculating visibility: $e'));
    }
  }

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
        if (object.type == CelestialType.star) {
          return HeavenlyBody.SE_FIXSTAR;
        }
        return null;
    }
  }
}
