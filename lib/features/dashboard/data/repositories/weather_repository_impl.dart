import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/seeing_calculator.dart';
import '../../domain/entities/weather.dart';
import '../../domain/entities/daily_weather_data.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../datasources/open_meteo_weather_service.dart';

import '../../domain/entities/hourly_forecast.dart';

class WeatherRepositoryImpl implements IWeatherRepository {
  final OpenMeteoWeatherService _service;
  final SeeingCalculator _seeingCalculator = SeeingCalculator();

  WeatherRepositoryImpl(this._service);

  @override
  Future<Either<Failure, Weather>> getWeather(GeoLocation location) async {
    try {
      // AC#3: Fetch hourly forecast data (temp, humidity, windspeed, cloudcover)
      final hourlyData = await _service.getHourlyForecast(location);
      
      // Use current hour (index 0) for instant weather display
      final cloudCover = ((hourlyData['cloudCover'] as List)[0] as num?)?.toDouble() ?? 0.0;
      final temperature = ((hourlyData['temperature'] as List)[0] as num?)?.toDouble() ?? 0.0;
      final humidity = ((hourlyData['humidity'] as List)[0] as num?)?.toDouble() ?? 0.0;
      final windSpeed = ((hourlyData['windSpeed'] as List)[0] as num?)?.toDouble() ?? 0.0;

      // AC#1, AC#4: Calculate Seeing score using hourly forecast data
      final (seeingScore, seeingLabel) = _seeingCalculator.calculateSeeing(
        temperatures: (hourlyData['temperature'] as List).cast<double>(),
        windSpeeds: (hourlyData['windSpeed'] as List).cast<double>(),
        humidities: (hourlyData['humidity'] as List).cast<double>(),
      );
      
      return Right(Weather(
        cloudCover: cloudCover,
        temperatureC: temperature,
        humidity: humidity,
        windSpeedKph: windSpeed,
        seeingScore: seeingScore,
        seeingLabel: seeingLabel,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HourlyForecast>>> getHourlyForecast(GeoLocation location) async {
    try {
      final hourlyData = await _service.getHourlyForecast(location);
      final List<HourlyForecast> forecasts = [];
      
      final times = (hourlyData['time'] as List).cast<String>();
      final cloudCovers = (hourlyData['cloudCover'] as List).cast<double>();
      final temperatures = (hourlyData['temperature'] as List).cast<double>();
      final humidities = (hourlyData['humidity'] as List).cast<double>();
      final windSpeeds = (hourlyData['windSpeed'] as List).cast<double>();

      for (int i = 0; i < times.length; i++) {
        final time = DateTime.parse(times[i]);
        
        final (seeingScore, seeingLabel) = _seeingCalculator.calculateSeeing(
            temperatures: [temperatures[i]],
            windSpeeds: [windSpeeds[i]],
            humidities: [humidities[i]],
        );

          forecasts.add(HourlyForecast(
            time: time,

            cloudCover: cloudCovers[i],
            temperatureC: temperatures[i],
            humidity: humidities[i].round(),
            windSpeedKph: windSpeeds[i],
            seeingScore: seeingScore,
            seeingLabel: seeingLabel,
          ));
      }
      
      return Right(forecasts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyWeatherData>>> getDailyForecast(GeoLocation location) async {
    try {
      final hourlyData = await _service.getHourlyForecast(location);
      final List<DailyWeatherData> dailyForecasts = [];
      final now = DateTime.now();

      // We want 7 days
      for (int i = 0; i < 7; i++) {
        // Target 22:00 (10 PM) for each day as the "Stargazing Forecast"
        // Hourly data starts at 00:00 of the current day (usually, depends on API timezone, but Open-Meteo defaults to GMT or requested TZ)
        // Assuming Open-Meteo returns data starting from 00:00 of the requested day.
        // Index 22 = 22:00.
        final index = (i * 24) + 22;

        final cloudCovers = (hourlyData['cloudCover'] as List).cast<double>();
        
        if (index < cloudCovers.length) {
          final cloudCover = cloudCovers[index];
          final temperature = ((hourlyData['temperature'] as List)[index] as num?)?.toDouble() ?? 0.0;
          final humidity = ((hourlyData['humidity'] as List)[index] as num?)?.toDouble() ?? 0.0;
          final windSpeed = ((hourlyData['windSpeed'] as List)[index] as num?)?.toDouble() ?? 0.0;
          final weatherCode = ((hourlyData['weatherCode'] as List)[index] as num?)?.toInt() ?? 0;

          final (seeingScore, seeingLabel) = _seeingCalculator.calculateSeeing(
            temperatures: [temperature], // Pass single value as list
            windSpeeds: [windSpeed],
            humidities: [humidity],
          );

          dailyForecasts.add(DailyWeatherData(
            date: now.add(Duration(days: i)),
            weatherCode: weatherCode,
            weather: Weather(
              cloudCover: cloudCover,
              temperatureC: temperature,
              humidity: humidity,
              windSpeedKph: windSpeed,
              seeingScore: seeingScore,
              seeingLabel: seeingLabel,
            ),
          ));
        }
      }

      return Right(dailyForecasts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
