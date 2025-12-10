import 'package:astr/core/engine/models/location.dart';
import 'package:astr/core/engine/models/result.dart';

/// Interface for Light Pollution Service
/// Returns Bortle class (1-9) for a given location
abstract class ILightPollutionService {
  /// Get Bortle class for the given location
  /// Returns Result<int> where int is Bortle class (1-9)
  /// 1 = Darkest skies, 9 = Inner city
  Future<Result<int>> getBortleClass(Location location);
}
