import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astr/core/services/qualitative/qualitative_condition_service.dart';
import 'package:astr/core/engine/models/condition_result.dart';
import 'package:astr/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:astr/features/astronomy/presentation/providers/astronomy_provider.dart';
import 'package:astr/features/dashboard/presentation/providers/light_pollution_provider.dart';

/// Provider for the qualitative condition evaluation service
final qualitativeConditionServiceProvider = Provider<QualitativeConditionService>((ref) {
  return QualitativeConditionService();
});

/// Provider that evaluates current observing conditions and returns qualitative result
final conditionQualityProvider = FutureProvider<ConditionResult>((ref) async {
  // Get required data
  final weather = await ref.watch(weatherProvider.future);
  final astronomy = await ref.watch(astronomyProvider.future);

  // Get base MPSAS from light pollution (without moon adjustment)
  // QualitativeConditionService handles moon separately to avoid double-counting
  final lightPollution = ref.watch(lightPollutionProvider);

  // Get the service
  final service = ref.watch(qualitativeConditionServiceProvider);

  // Evaluate conditions using base MPSAS
  // The service will account for moon illumination in its weighted calculation
  return service.evaluate(
    cloudCover: weather.cloudCover,
    moonIllumination: astronomy.moonPhaseInfo.illumination,
    mpsas: lightPollution.mpsas, // Use base MPSAS, not moon-adjusted
  );
});
