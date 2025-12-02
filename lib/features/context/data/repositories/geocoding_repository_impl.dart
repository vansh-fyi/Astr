import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/geo_location.dart';
import '../../domain/repositories/i_geocoding_repository.dart';
import '../datasources/geocoding_service.dart';

class GeocodingRepositoryImpl implements IGeocodingRepository {
  final GeocodingService _service;

  GeocodingRepositoryImpl(this._service);

  @override
  Future<Either<Failure, List<GeoLocation>>> searchLocations(String query) async {
    try {
      final locations = await _service.searchLocations(query);
      return Right(locations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getPlaceName(double lat, double lon) async {
    try {
      final name = await _service.getPlaceName(lat, lon);
      return Right(name);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
