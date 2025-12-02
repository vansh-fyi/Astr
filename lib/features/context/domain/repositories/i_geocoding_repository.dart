import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/geo_location.dart';

abstract class IGeocodingRepository {
  Future<Either<Failure, List<GeoLocation>>> searchLocations(String query);
  Future<Either<Failure, String>> getPlaceName(double lat, double lon);
}
