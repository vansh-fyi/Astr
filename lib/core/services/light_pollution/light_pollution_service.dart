import '../../engine/models/location.dart';
import '../../engine/models/result.dart';
import '../../error/light_pollution_failure.dart';
import 'data/offline_lp_data_source.dart';
import 'data/online_lp_data_source.dart';
import 'i_light_pollution_service.dart';

/// Hybrid Light Pollution Service
/// Implements online-first strategy with offline fallback
/// AC#1: Tries online API first, falls back to offline PNG on failure
/// AC#6: Returns Result.failure only if both methods fail
class LightPollutionService implements ILightPollutionService {

  LightPollutionService({
    OnlineLPDataSource? onlineSource,
    OfflineLPDataSource? offlineSource,
  })  : _onlineSource = onlineSource ?? OnlineLPDataSource(),
        _offlineSource = offlineSource ?? OfflineLPDataSource();
  final OnlineLPDataSource _onlineSource;
  final OfflineLPDataSource _offlineSource;

  @override
  Future<Result<int>> getBortleClass(Location location) async {
    // Step 1: Try online source first
    final int? onlineResult = await _onlineSource.getBortleClass(location);
    
    if (onlineResult != null) {
      return Result.success(onlineResult);
    }

    // Step 2: Fallback to offline source
    final int? offlineResult = await _offlineSource.getBortleClass(location);
    
    if (offlineResult != null) {
      return Result.success(offlineResult);
    }

    // Step 3: Both failed
    return Result.failure(
      const LightPollutionFailure(
        'Unable to determine light pollution: both online and offline sources failed',
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _onlineSource.dispose();
    _offlineSource.clearCache();
  }
}
