import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../entities/daily_forecast.dart';

abstract class IPlannerRepository {
  Future<Either<Failure, List<DailyForecast>>> get7DayForecast(GeoLocation location, int bortleClass);
}
