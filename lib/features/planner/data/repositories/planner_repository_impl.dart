import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/daily_forecast.dart';
import '../../domain/repositories/i_planner_repository.dart';

class PlannerRepositoryImpl implements IPlannerRepository {

  PlannerRepositoryImpl({required this.client});
  final http.Client client;

  @override
  Future<Either<Failure, List<DailyForecast>>> get7DayForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final Uri uri = Uri.parse(
        '${ApiConfig.weatherBaseUrl}/forecast?latitude=$latitude&longitude=$longitude&daily=weathercode,cloudcover_mean,precipitation_probability_max&timezone=auto&forecast_days=7',
      );

      final http.Response response = await client.get(uri);

      if (response.statusCode != 200) {
        return Left<Failure, List<DailyForecast>>(ServerFailure('Failed to fetch forecast: ${response.statusCode}'));
      }

      final data = json.decode(response.body);
      final daily = data['daily'];
      final List<String> dates = (daily['time'] as List).cast<String>();
      final List<int> weatherCodes = (daily['weathercode'] as List).cast<int>();
      final List<num> cloudCovers = (daily['cloudcover_mean'] as List).cast<num>();
      // Note: Precipitation probability is fetched but currently not used in the entity as per spec, 
      // but good to have for future.

      final List<DailyForecast> forecasts = <DailyForecast>[];

      for (int i = 0; i < dates.length; i++) {
        final DateTime date = DateTime.parse(dates[i]);
        final double cloudCover = cloudCovers[i].toDouble();
        final String code = weatherCodes[i].toString();

        // Placeholder star rating logic - will be refined in PlannerLogic or here if we move logic to repo.
        // For now, let's just map the raw data. The actual "Star Rating" calculation involving Moon Phase
        // is specified to be in `PlannerLogic` (Task 3), but the Repository needs to return a `DailyForecast`
        // which HAS a `starRating`. 
        // 
        // DECISION: The Repository will fetch raw weather data. The Domain Logic (UseCase or Service) 
        // should ideally combine Weather + Astronomy to produce the final `DailyForecast`.
        // However, the `IPlannerRepository` contract returns `List<DailyForecast>`.
        // This implies the Repo is responsible for constructing it.
        // 
        // To strictly follow the AC "Star Rating logic considers both Cloud Cover and Moon Phase",
        // and knowing `AstronomyEngine` is a separate dependency, we have two options:
        // 1. Inject `AstronomyEngine` into `PlannerRepository`.
        // 2. Have Repo return a `WeatherForecast` DTO, and a Domain UseCase combines it with Astro data to return `DailyForecast`.
        // 
        // Given the current simple architecture and Task 3 "Implement PlannerLogic", 
        // let's assume `PlannerLogic` is a Domain Service or UseCase that orchestrates this.
        // BUT, the current task says "Implement PlannerRepository" and "Map API response to DailyForecast".
        // 
        // Let's implement a basic mapping here with a default/placeholder star rating (e.g., based only on cloud cover)
        // and let the `PlannerLogic` (Task 3) refine or wrap this. 
        // OR, better yet, let's modify the plan slightly to be cleaner:
        // The Repo returns `DailyForecast` with weather data. The `starRating` might be partial here.
        // 
        // Wait, Task 3 says "Implement PlannerLogic... Integrate AstronomyEngine...". 
        // This suggests `PlannerLogic` is the consumer of the Repo.
        // So `PlannerRepository` should probably return something simpler, OR `PlannerLogic` *IS* the class that calls the Repo?
        // 
        // Let's look at the Architecture. 
        // `features/planner/domain` -> `PlannerLogic`.
        // `features/planner/data` -> `PlannerRepository`.
        // 
        // If `PlannerLogic` is a UseCase, it calls `PlannerRepository`.
        // If `PlannerRepository` returns `DailyForecast`, it needs to know the Star Rating.
        // 
        // Let's make `PlannerRepository` return the weather data, and `PlannerLogic` combine it.
        // But the AC says "Map API response to DailyForecast domain entities" in Task 2.
        // This implies `DailyForecast` is the output of the Repo.
        // 
        // I will implement `PlannerRepository` to calculate a *preliminary* star rating based on Cloud Cover only,
        // and `PlannerLogic` (Task 3) will likely be a UseCase that *updates* or *re-calculates* this with Moon data,
        // OR `PlannerLogic` will simply use the Repo's output if I inject `AstronomyEngine` here.
        // 
        // Actually, looking at Task 3: "Integrate AstronomyEngine... to calculate moon phase".
        // This strongly suggests the logic lives outside the repo.
        // 
        // I will initialize `starRating` to 0 or a cloud-based value here.
        
        int simpleStarRating = 1;
        if (cloudCover < 20) {
          simpleStarRating = 5;
        } else if (cloudCover < 40) simpleStarRating = 4;
        else if (cloudCover < 60) simpleStarRating = 3;
        else if (cloudCover < 80) simpleStarRating = 2;

        forecasts.add(DailyForecast(
          date: date,
          cloudCoverAvg: cloudCover,
          moonIllumination: 0, // Placeholder, to be filled by Logic/UseCase
          weatherCode: code,
          starRating: simpleStarRating, // Preliminary, based on clouds only
        ));
      }

      return Right<Failure, List<DailyForecast>>(forecasts);
    } catch (e) {
      return Left<Failure, List<DailyForecast>>(ServerFailure(e.toString()));
    }
  }
}
