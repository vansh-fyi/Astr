import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/astronomy/domain/repositories/i_astro_engine.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../../features/dashboard/data/datasources/open_meteo_weather_service.dart';
import '../../../astronomy/domain/entities/moon_phase_info.dart';
import '../../domain/entities/daily_forecast.dart';
import '../../domain/logic/planner_logic.dart';
import '../../domain/repositories/i_planner_repository.dart';

class PlannerRepository implements IPlannerRepository {

  PlannerRepository(this._weatherService, this._astroEngine, this._plannerLogic);
  final OpenMeteoWeatherService _weatherService;
  final IAstroEngine _astroEngine;
  final PlannerLogic _plannerLogic;

  @override
  Future<Either<Failure, List<DailyForecast>>> get7DayForecast(GeoLocation location, int bortleClass) async {
    try {
      // 1. Fetch Hourly Weather Data (7 days)
      final Map<String, dynamic> hourlyData = await _weatherService.getHourlyForecast(location);
      
      final List<DailyForecast> forecasts = <DailyForecast>[];
      final DateTime now = DateTime.now();
      
      // 2. Process each day
      for (int i = 0; i < 7; i++) {
        // Target 22:00 (10 PM) for stargazing conditions
        final int index = (i * 24) + 22;
        
        final List<double> cloudCovers = (hourlyData['cloudCover'] as List).cast<double>();
        final List<double> weatherCodes = (hourlyData['weatherCode'] as List).cast<double>(); // API returns doubles usually
        
        if (index < cloudCovers.length) {
          final double cloudCover = cloudCovers[index];
          final int weatherCode = weatherCodes[index].toInt();
          
          // 3. Get Moon Illumination for that night
          final DateTime date = now.add(Duration(days: i));
          // Set time to 22:00 for moon calculation
          final DateTime nightTime = DateTime(date.year, date.month, date.day, 22);
          
          final Either<Failure, MoonPhaseInfo> moonResult = await _astroEngine.getMoonPhaseInfo(time: nightTime);
          
          // Handle Moon Result (Default to 0.0 if failure, though unlikely if initialized)
          final double moonIllumination = moonResult.fold(
            (Failure l) => 0.0, 
            (MoonPhaseInfo r) => r.illumination
          );
          
          // 4. Calculate Star Rating
          final int starRating = _plannerLogic.calculateStarRating(
            cloudCoverAvg: cloudCover,
            moonIllumination: moonIllumination,
            bortleScale: bortleClass,
          );
          
          forecasts.add(DailyForecast(
            date: date,
            cloudCoverAvg: cloudCover,
            moonIllumination: moonIllumination,
            weatherCode: weatherCode,
            starRating: starRating,
          ));
        }
      }
      
      return Right(forecasts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
