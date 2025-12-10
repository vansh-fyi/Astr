import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/location.dart';

/// Base class for calculation commands that can be sent to isolates
abstract class CalculationCommand {
  const CalculationCommand();
}

/// Command to calculate horizontal coordinates from equatorial coordinates
class CalculatePositionCommand extends CalculationCommand {
  final double rightAscension;
  final double declination;
  final double latitude;
  final double longitude;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;

  const CalculatePositionCommand({
    required this.rightAscension,
    required this.declination,
    required this.latitude,
    required this.longitude,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
  });

  EquatorialCoordinates get equatorialCoordinates =>
      EquatorialCoordinates(
        rightAscension: rightAscension,
        declination: declination,
      );

  Location get location => Location(
        latitude: latitude,
        longitude: longitude,
      );

  DateTime get dateTime =>
      DateTime.utc(year, month, day, hour, minute, second);
}

/// Command to calculate rise/set times
class CalculateRiseSetCommand extends CalculationCommand {
  final double rightAscension;
  final double declination;
  final double latitude;
  final double longitude;
  final int year;
  final int month;
  final int day;

  const CalculateRiseSetCommand({
    required this.rightAscension,
    required this.declination,
    required this.latitude,
    required this.longitude,
    required this.year,
    required this.month,
    required this.day,
  });

  EquatorialCoordinates get equatorialCoordinates =>
      EquatorialCoordinates(
        rightAscension: rightAscension,
        declination: declination,
      );

  Location get location => Location(
        latitude: latitude,
        longitude: longitude,
      );

  DateTime get date => DateTime.utc(year, month, day);
}

/// Result container for horizontal coordinates calculation
class HorizontalCoordinatesResult {
  final double altitude;
  final double azimuth;

  const HorizontalCoordinatesResult({
    required this.altitude,
    required this.azimuth,
  });

  HorizontalCoordinates toCoordinates() => HorizontalCoordinates(
        altitude: altitude,
        azimuth: azimuth,
      );
}

/// Result container for rise/set times calculation
class RiseSetTimesResult {
  final DateTime? riseTime;
  final DateTime? transitTime;
  final DateTime? setTime;
  final bool isCircumpolar;
  final bool neverRises;

  const RiseSetTimesResult({
    this.riseTime,
    this.transitTime,
    this.setTime,
    this.isCircumpolar = false,
    this.neverRises = false,
  });
}
