import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../entities/light_pollution.dart';

abstract class ILightPollutionService {
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location);
}
