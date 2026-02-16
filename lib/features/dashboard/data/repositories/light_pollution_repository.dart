import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../data_layer/models/zone_data.dart';
import '../../../data_layer/repositories/cached_zone_repository.dart';
import '../../../data_layer/services/h3_service.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';

/// Light pollution repository using remote zone API.
///
/// **Data Source:**
/// CachedZoneRepository (Remote API + Hive cache) - H3-indexed satellite data
///
/// **Dark Sky Default:**
/// Locations not in the lit-areas database return Bortle 1 (pristine dark sky).
/// These are the best stargazing locations with no artificial light pollution.
class LightPollutionRepository implements ILightPollutionService {
  LightPollutionRepository({
    required CachedZoneRepository zoneRepository,
    required H3Service h3Service,
  })  : _zoneRepository = zoneRepository,
        _h3Service = h3Service;

  final CachedZoneRepository _zoneRepository;
  final H3Service _h3Service;

  /// H3 Resolution used for zone lookups.
  /// Resolution 8 = ~461m average cell edge length (optimal for stargazing precision).
  static const int _h3Resolution = 8;

  @override
  Future<Either<Failure, LightPollution>> getLightPollution(GeoLocation location) async {
    try {
      // Step 1: Convert lat/lon to H3 index at resolution 8
      final BigInt h3Index = _h3Service.latLonToH3(
        location.latitude,
        location.longitude,
        _h3Resolution,
      );

      // Step 2: Query zone data (checks cache first, then remote API)
      // Returns pristine dark sky default if not in database
      final ZoneData zoneData = await _zoneRepository.getZoneData(h3Index);

      // Step 3: Convert ZoneData to LightPollution entity
      return Right<Failure, LightPollution>(LightPollution(
        visibilityIndex: zoneData.bortleClass,
        brightnessRatio: zoneData.ratio,
        mpsas: zoneData.sqm,
        source: zoneData.bortleClass == 1 
            ? LightPollutionSource.estimated  // Dark sky default
            : LightPollutionSource.precise,    // From database
        zone: zoneData.bortleClass.toString(),
      ));
    } catch (e) {
      debugPrint('LightPollutionRepository: Lookup failed: $e');
      return Left<Failure, LightPollution>(ServerFailure('Light pollution lookup failed: $e'));
    }
  }}
