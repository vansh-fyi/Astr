import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../entities/daily_weather_data.dart';
import '../entities/hourly_forecast.dart';
import '../entities/weather.dart';

abstract class IWeatherRepository {
  Future<Either<Failure, Weather>> getWeather(GeoLocation location);
  Future<Either<Failure, List<DailyWeatherData>>> getDailyForecast(GeoLocation location);
  Future<Either<Failure, List<HourlyForecast>>> getHourlyForecast(GeoLocation location);
}
