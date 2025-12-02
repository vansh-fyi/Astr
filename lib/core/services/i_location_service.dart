import 'package:fpdart/fpdart.dart';
import '../../features/context/domain/entities/geo_location.dart';
import '../error/failure.dart';

abstract class ILocationService {
  Future<Either<Failure, GeoLocation>> getCurrentLocation();
}
