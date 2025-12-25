import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/context/domain/entities/geo_location.dart';
import '../error/failure.dart';
import 'i_location_service.dart';

class DeviceLocationService implements ILocationService {
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
      final Position position = await Geolocator.getCurrentPosition();
      return Right(GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      return Left(LocationFailure(e.toString()));
    }
  }
}
