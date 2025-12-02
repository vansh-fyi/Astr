import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';
import '../datasources/png_map_service.dart';

class LightPollutionRepository implements ILightPollutionService {
  final Dio _dio;
  final PngMapService _pngService;

  LightPollutionRepository(this._dio, this._pngService);

  @override
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location) async {
    // 1. Try API (Vercel Backend)
    try {
      final response = await _dio.get(
        'https://astr-self.vercel.app/api/light-pollution',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(LightPollution.fromJson(response.data));
      }
    } catch (e) {
      // API failed or offline, fall through to fallback
    }

    // 2. Try Fallback PNG Map
    try {
      final fallbackData = await _pngService.getLightPollution(location);
      if (fallbackData != null) {
        return Right(fallbackData);
      }
    } catch (e) {
      // Ignore error
    }

    // 3. Return Unknown/Failure if both fail
    return Left(ServerFailure('Could not determine light pollution data'));
  }
}
