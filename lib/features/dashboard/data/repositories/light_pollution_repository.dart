import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';
import '../datasources/png_map_service.dart';

/// Light pollution repository using Light Pollution Atlas (PNG map)
/// 
/// The PNG map is based on the World Atlas of Artificial Night Sky Brightness,
/// which is calibrated for stargazing and Bortle scale accuracy.
class LightPollutionRepository implements ILightPollutionService {
  final PngMapService _pngService;

  LightPollutionRepository(this._pngService);

  @override
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location) async {
    try {
      final result = await _pngService.getLightPollution(location);
      if (result != null) {
        return Right(result);
      }
      return Left(ServerFailure('Could not determine light pollution data'));
    } catch (e) {
      return Left(ServerFailure('Light pollution lookup failed: $e'));
    }
  }
}


