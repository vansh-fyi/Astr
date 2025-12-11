import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweph/sweph.dart';

// Conditional imports for platform-specific functionality
import 'astronomy_service_mobile.dart'
    if (dart.library.html) 'astronomy_service_web.dart';

/// Provider for the AstronomyService
final astronomyServiceProvider = Provider<AstronomyService>((ref) {
  return AstronomyService();
});

/// Service responsible for all astronomical calculations using Swiss Ephemeris
class AstronomyService {
  bool _isInitialized = false;

  /// Initialize the Swiss Ephemeris library
  /// This must be called before any calculations are performed.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await initializeSwephPlatform();
      _isInitialized = true;
      debugPrint('AstronomyService: Initialized successfully');
    } catch (e) {
      debugPrint('AstronomyService: Initialization failed: $e');
      // Don't rethrow - allow app to continue with degraded functionality
      _isInitialized = false;
    }
  }

  /// Calculate Rise, Set, and Transit times for a celestial body
  /// Returns a Map with 'rise', 'set', 'transit' keys as DateTime (or null if not found)
  /// Calculate Rise, Set, and Transit times for a celestial body
  /// Returns a Map with 'rise', 'set', 'transit' keys as DateTime (or null if not found)
  Future<Map<String, DateTime?>> calculateRiseSetTransit({
    required HeavenlyBody body,
    String? starName,
    required DateTime date,
    required double lat,
    required double long,
  }) async {
    await checkInitialized();

    // Calculate JD for the start of the day (Local Midnight -> UTC)
    // This ensures we find events for the selected date, not tomorrow.
    final localMidnight = DateTime(date.year, date.month, date.day);
    final utcStart = localMidnight.toUtc();

    // Convert UTC DateTime to Julian Day
    final jd = Sweph.swe_julday(
      utcStart.year,
      utcStart.month,
      utcStart.day,
      utcStart.hour + utcStart.minute / 60.0 + utcStart.second / 3600.0,
      CalendarType.SE_GREG_CAL,
    );

    // Flags: Swiss Ephemeris, Topocentric (observer location)
    final flags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_TOPOCTR;

    // GeoPosition for the observer
    final geopos = GeoPosition(long, lat);

    // Calculate Rise
    final rise = _calcEvent(body, jd, flags, RiseSetTransitFlag.SE_CALC_RISE, geopos);
    // Calculate Set
    final set = _calcEvent(body, jd, flags, RiseSetTransitFlag.SE_CALC_SET, geopos);
    // Calculate Transit (Meridian Crossing)
    final transit = _calcEvent(body, jd, flags, RiseSetTransitFlag.SE_CALC_MTRANSIT, geopos);

    return {
      'rise': _jdToDateTime(rise),
      'set': _jdToDateTime(set),
      'transit': _jdToDateTime(transit),
    };
  }

  /// Calculate Altitude Trajectory for a celestial body over a specified duration
  /// Returns a list of GraphPoints (time, altitude) every 15 minutes
  ///
  /// NOTE: Heavy calculation (>16ms) that should ideally run in isolate, but sweph's
  /// native FFI bindings are incompatible with Dart isolates. Future optimization may
  /// require switching to a pure Dart astronomy library.
  Future<List<GraphPoint>> calculateAltitudeTrajectory({
    required HeavenlyBody body,
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async {
    await checkInitialized();
    final points = <GraphPoint>[];
    final geopos = GeoPosition(long, lat);

    final totalMinutes = duration.inMinutes;
    final intervals = (totalMinutes / 15).ceil();

    for (int i = 0; i <= intervals; i++) {
      final time = startTime.add(Duration(minutes: i * 15));
      if (time.difference(startTime) > duration) break;

      final utcTime = time.toUtc();

      final jd = Sweph.swe_julday(
        utcTime.year,
        utcTime.month,
        utcTime.day,
        utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );

      // Calculate Equatorial Position
      final flags = SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
      final xx = Sweph.swe_calc_ut(jd, body, flags);

      // Convert to Horizon Coordinates
      final xin = Coordinates(xx.longitude, xx.latitude, xx.distance);
      final azAlt = Sweph.swe_azalt(
        jd,
        AzAltMode.SE_EQU2HOR,
        geopos,
        0.0,
        10.0,
        xin,
      );

      points.add(GraphPoint(time: time, value: azAlt.trueAltitude));
    }

    return points;
  }

  /// Calculate Altitude Trajectory for a fixed object (RA/Dec) over a specified duration
  /// Returns a list of GraphPoints (time, altitude) every 15 minutes
  ///
  /// NOTE: Heavy calculation (>16ms) - see calculateAltitudeTrajectory for isolate limitation details
  Future<List<GraphPoint>> calculateFixedObjectTrajectory({
    required double ra, // Right Ascension in degrees
    required double dec, // Declination in degrees
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async {
    await checkInitialized();
    final points = <GraphPoint>[];
    final geopos = GeoPosition(long, lat);

    final totalMinutes = duration.inMinutes;
    final intervals = (totalMinutes / 15).ceil();

    for (int i = 0; i <= intervals; i++) {
      final time = startTime.add(Duration(minutes: i * 15));
      if (time.difference(startTime) > duration) break;

      final utcTime = time.toUtc();

      final jd = Sweph.swe_julday(
        utcTime.year,
        utcTime.month,
        utcTime.day,
        utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );

      final xin = Coordinates(ra, dec, 1.0);

      final azAlt = Sweph.swe_azalt(
        jd,
        AzAltMode.SE_EQU2HOR,
        geopos,
        0.0,
        10.0,
        xin,
      );

      points.add(GraphPoint(time: time, value: azAlt.trueAltitude));
    }

    return points;
  }

  /// Calculate Moon Interference Trajectory over a specified duration
  /// Returns a list of GraphPoints (time, interference score) every 15 minutes
  /// Interference = Altitude * Illumination (0-1)
  ///
  /// NOTE: Heavy calculation (>16ms) - see calculateAltitudeTrajectory for isolate limitation details
  Future<List<GraphPoint>> calculateMoonTrajectory({
    required DateTime startTime,
    required double lat,
    required double long,
    Duration duration = const Duration(hours: 12),
  }) async {
    await checkInitialized();
    final points = <GraphPoint>[];
    final geopos = GeoPosition(long, lat);

    final totalMinutes = duration.inMinutes;
    final intervals = (totalMinutes / 15).ceil();

    for (int i = 0; i <= intervals; i++) {
      final time = startTime.add(Duration(minutes: i * 15));
      if (time.difference(startTime) > duration) break;

      final utcTime = time.toUtc();

      final jd = Sweph.swe_julday(
        utcTime.year,
        utcTime.month,
        utcTime.day,
        utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );

      // Calculate Moon Position
      final flags = SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
      final xx = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);

      // Calculate Moon Altitude
      final xin = Coordinates(xx.longitude, xx.latitude, xx.distance);
      final azAlt = Sweph.swe_azalt(
        jd,
        AzAltMode.SE_EQU2HOR,
        geopos,
        0.0,
        10.0,
        xin,
      );

      // Calculate Moon Phase
      final pheno = Sweph.swe_pheno_ut(jd, HeavenlyBody.SE_MOON, flags);

      double illumination = 0.0;
      if (pheno.length > 1) {
        illumination = pheno[1];
      }

      // Calculate Interference
      double altitude = azAlt.trueAltitude;
      double interference = 0.0;

      if (altitude > 0) {
        interference = altitude * illumination;
      }

      points.add(GraphPoint(time: time, value: interference));
    }

    return points;
  }

  /// Helper to calculate a specific event (Rise/Set/Transit)
  double? _calcEvent(HeavenlyBody body, double jd, SwephFlag flags, RiseSetTransitFlag transitFlag, GeoPosition geopos) {
    try {
      final result = Sweph.swe_rise_trans(
        jd,
        body,
        flags,
        transitFlag,
        geopos,
        0, // pressure
        0, // temperature
      );
      return result; // Return Julian Day of event
    } catch (e) {
      // Event might not occur (e.g., circumpolar)
      return null;
    }
  }

  /// Convert Julian Day to DateTime (Local Time)
  DateTime? _jdToDateTime(double? jd) {
    if (jd == null) return null;
    return Sweph.swe_revjul(jd, CalendarType.SE_GREG_CAL).toLocal();
  }

  /// Calculate Moon Phase (Illumination 0.0-1.0) for a specific time
  Future<double> getMoonPhase(DateTime time) async {
    await checkInitialized();
    final utcTime = time.toUtc();
    final jd = Sweph.swe_julday(
      utcTime.year,
      utcTime.month,
      utcTime.day,
      utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0,
      CalendarType.SE_GREG_CAL,
    );

    final flags = SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
    final pheno = Sweph.swe_pheno_ut(jd, HeavenlyBody.SE_MOON, flags);

    if (pheno.length > 1) {
      return pheno[1];
    }
    return 0.0;
  }

  /// Calculate the "Night Window" for a given date/time
  /// Returns start (Sunset) and end (Sunrise)
  Future<Map<String, DateTime>> getNightWindow({
    required DateTime date,
    required double lat,
    required double long,
  }) async {
    await checkInitialized();

    // Calculate events for the given date
    final todayEvents = await calculateRiseSetTransit(
      body: HeavenlyBody.SE_SUN,
      date: date,
      lat: lat,
      long: long,
    );

    final todaySet = todayEvents['set'];
    final todayRise = todayEvents['rise'];

    // Calculate events for tomorrow
    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowEvents = await calculateRiseSetTransit(
      body: HeavenlyBody.SE_SUN,
      date: tomorrow,
      lat: lat,
      long: long,
    );
    final tomorrowRise = tomorrowEvents['rise'];

    // Calculate events for yesterday
    final yesterday = date.subtract(const Duration(days: 1));
    final yesterdayEvents = await calculateRiseSetTransit(
      body: HeavenlyBody.SE_SUN,
      date: yesterday,
      lat: lat,
      long: long,
    );
    final yesterdaySet = yesterdayEvents['set'];

    DateTime start;
    DateTime end;

    // Logic:
    // If date is before today's sunrise (early morning), night started yesterday evening.
    if (todayRise != null && date.isBefore(todayRise)) {
        start = yesterdaySet ?? date.subtract(const Duration(hours: 6)); // Fallback
        end = todayRise;
    }
    // If date is after today's sunset (evening), night starts today evening.
    else if (todaySet != null && date.isAfter(todaySet)) {
        start = todaySet;
        end = tomorrowRise ?? date.add(const Duration(hours: 12)); // Fallback
    }
    // If date is during the day (between rise and set), show UPCOMING night.
    else {
        start = todaySet ?? date; // Fallback to now if no set
        end = tomorrowRise ?? date.add(const Duration(hours: 12));
    }

    return {'start': start, 'end': end};
  }

  Future<void> checkInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
}
