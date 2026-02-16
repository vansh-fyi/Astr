import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/context/domain/entities/geo_location.dart';
import '../error/failure.dart';
import 'i_location_service.dart';

class DeviceLocationService implements ILocationService {
  DeviceLocationService({
    this.timeoutDuration = const Duration(seconds: 10), // NFR-10: Default 10s timeout
  });

  final Duration timeoutDuration;

  @override
  Future<Either<Failure, GeoLocation>> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(LocationFailure('Location services are disabled.'));
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const Left(PermissionFailure('Location permissions are denied'));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const Left(PermissionFailure(
          'Location permissions are permanently denied, we cannot request permissions.'));
    }

    try {
      // NFR-10: GPS timeout after configured duration (default 10s)
      // Note: Only use LocationSettings.timeLimit — do NOT add an outer .timeout()
      // as it races with the platform-level timeout on Android, causing premature
      // termination where GPS loads for ~1s then dies.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeoutDuration,
        ),
      );

      return Right(GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on TimeoutException {
      // NFR-10: Specific timeout failure with user-friendly message
      return const Left(TimeoutFailure('GPS Unavailable. Restart or hit Refresh.'));
    } catch (e) {
      // On Android, geolocator_android throws platform exceptions for timeouts
      // that surface as generic Exception with 'TimeLimit' in the message.
      final String msg = e.toString();
      if (msg.contains('TimeLimit') || msg.contains('timeout')) {
        return const Left(TimeoutFailure('GPS Unavailable. Restart or hit Refresh.'));
      }
      return Left(LocationFailure(msg));
    }
  }
}
