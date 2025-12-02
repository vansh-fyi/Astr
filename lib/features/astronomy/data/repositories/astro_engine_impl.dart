import 'package:astr/core/error/failure.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:astr/features/astronomy/domain/repositories/i_astro_engine.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sweph/sweph.dart';

class AstroEngineImpl implements IAstroEngine {
  
  static Future<void> initialize() async {
    await Sweph.init(epheAssets: [
      'packages/sweph/assets/ephe/sepl_18.se1',
      'packages/sweph/assets/ephe/semo_18.se1',
      'packages/sweph/assets/ephe/seas_18.se1',
    ]);
  }

  @override
  Future<Either<Failure, CelestialPosition>> getPosition({
    required CelestialBody body,
    required DateTime time,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final jd = _getJulianDay(time);
      final planetId = _mapBodyToSweph(body);
      final flags = SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;

      // Calculate Position (RA/Dec/Dist)
      final xx = Sweph.swe_calc_ut(jd, planetId, flags);
      
      // Calculate Alt/Az
      final geopos = GeoPosition(longitude, latitude, 0.0);
      final xin = Coordinates(xx.longitude, xx.latitude, xx.distance);
      // SE_EQU2HOR: Equatorial to Horizon
      final azalt = Sweph.swe_azalt(jd, AzAltMode.SE_EQU2HOR, geopos, 0.0, 10.0, xin);
      // azalt: AzimuthAltitudeInfo

      // Calculate Magnitude
      final pheno = Sweph.swe_pheno_ut(jd, planetId, flags);

      return Right(CelestialPosition(
        body: body,
        name: body.displayName,
        time: time,
        altitude: azalt.trueAltitude, // Using True Altitude
        azimuth: azalt.azimuth,
        distance: xx.distance,
        magnitude: pheno[4],
      ));
    } catch (e) {
      return Left(CalculationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CelestialPosition>> getDeepSkyPosition({
    required double ra,
    required double dec,
    required String name,
    required DateTime time,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final jd = _getJulianDay(time);
      
      // Calculate Alt/Az
      final geopos = GeoPosition(longitude, latitude, 0.0);
      // Distance is irrelevant for infinite distance objects, using 1.0 AU as placeholder
      final xin = Coordinates(ra, dec, 1.0); 
      
      // SE_EQU2HOR: Equatorial to Horizon
      // For fixed objects (J2000), we might need to precess to current date if high accuracy is needed.
      // However, for general visibility, J2000 RA/Dec fed directly into swe_azalt with SE_EQU2HOR 
      // treats them as "of date" unless we handle precession manually.
      // Sweph.swe_azalt assumes the coordinates are for the given JD.
      // To be strictly accurate, we should precess J2000 to Current Date.
      // But for < 1 degree accuracy, J2000 is often "close enough" for visual observing planning 
      // over short timeframes, though precession is ~50 arcsec/year. 
      // Over 20 years (2000-2025), that's ~1000 arcsec = ~16 arcmin = ~0.25 degrees.
      // This is acceptable for this app's current scope (visual planning).
      
      final azalt = Sweph.swe_azalt(jd, AzAltMode.SE_EQU2HOR, geopos, 0.0, 10.0, xin);

      return Right(CelestialPosition(
        body: null,
        name: name,
        time: time,
        altitude: azalt.trueAltitude,
        azimuth: azalt.azimuth,
        distance: 0.0, // Infinite/Unknown
        magnitude: 0.0, // Unknown/Variable
      ));
    } catch (e) {
      return Left(CalculationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MoonPhaseInfo>> getMoonPhaseInfo({
    required DateTime time,
  }) async {
    try {
      final jd = _getJulianDay(time);
      final flags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
      
      // Calculate Sun Position
      final sunPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
      final sunLong = sunPos.longitude;

      // Calculate Moon Position
      final moonPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);
      final moonLong = moonPos.longitude;

      // Calculate Phase Angle (0-360)
      double phaseAngle = (moonLong - sunLong) % 360;
      if (phaseAngle < 0) phaseAngle += 360;

      // Calculate Illumination
      final pheno = Sweph.swe_pheno_ut(jd, HeavenlyBody.SE_MOON, flags);
      
      return Right(MoonPhaseInfo(
        phaseAngle: phaseAngle,
        illumination: pheno[1],
      ));
    } catch (e) {
      return Left(CalculationFailure(e.toString()));
    }
  }

  double _getJulianDay(DateTime time) {
    final utc = time.toUtc();
    final hour = utc.hour + utc.minute / 60.0 + utc.second / 3600.0 + utc.millisecond / 3600000.0;
    return Sweph.swe_julday(utc.year, utc.month, utc.day, hour, CalendarType.SE_GREG_CAL);
  }

  HeavenlyBody _mapBodyToSweph(CelestialBody body) {
    switch (body) {
      case CelestialBody.sun: return HeavenlyBody.SE_SUN;
      case CelestialBody.moon: return HeavenlyBody.SE_MOON;
      case CelestialBody.mercury: return HeavenlyBody.SE_MERCURY;
      case CelestialBody.venus: return HeavenlyBody.SE_VENUS;
      case CelestialBody.mars: return HeavenlyBody.SE_MARS;
      case CelestialBody.jupiter: return HeavenlyBody.SE_JUPITER;
      case CelestialBody.saturn: return HeavenlyBody.SE_SATURN;
      case CelestialBody.uranus: return HeavenlyBody.SE_URANUS;
      case CelestialBody.neptune: return HeavenlyBody.SE_NEPTUNE;
      case CelestialBody.pluto: return HeavenlyBody.SE_PLUTO;
    }
  }
}
