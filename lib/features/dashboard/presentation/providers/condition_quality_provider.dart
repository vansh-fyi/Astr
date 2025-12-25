import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/models/condition_result.dart';
import '../../../../core/services/qualitative/qualitative_condition_service.dart';
import '../../../astronomy/domain/entities/astronomy_state.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/entities/weather.dart';
import 'light_pollution_provider.dart';
import 'weather_provider.dart';

/// Provider for the qualitative condition evaluation service
final Provider<QualitativeConditionService> qualitativeConditionServiceProvider = Provider<QualitativeConditionService>((ProviderRef<QualitativeConditionService> ref) {
  return QualitativeConditionService();
});

/// Provider that evaluates current observing conditions and returns qualitative result
final FutureProvider<ConditionResult> conditionQualityProvider = FutureProvider<ConditionResult>((FutureProviderRef<ConditionResult> ref) async {
  // Get required data
  final Weather weather = await ref.watch(weatherProvider.future);
  final AstronomyState astronomy = await ref.watch(astronomyProvider.future);

  // Get base MPSAS from light pollution (without moon adjustment)
  // QualitativeConditionService handles moon separately to avoid double-counting
  final LightPollution lightPollution = ref.watch(lightPollutionProvider);

  // Get the service
  final QualitativeConditionService service = ref.watch(qualitativeConditionServiceProvider);

  // Evaluate conditions using base MPSAS
  // The service will account for moon illumination in its weighted calculation
  return service.evaluate(
    cloudCover: weather.cloudCover,
    moonIllumination: astronomy.moonPhaseInfo.illumination,
    mpsas: lightPollution.mpsas, // Use base MPSAS, not moon-adjusted
  );
});
