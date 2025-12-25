import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/darkness_calculator.dart';
import '../../../astronomy/domain/entities/astronomy_state.dart';
import '../../../astronomy/domain/entities/celestial_body.dart';
import '../../../astronomy/domain/entities/celestial_position.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../domain/entities/light_pollution.dart';
import 'light_pollution_provider.dart';

class DarknessState {

  const DarknessState({
    required this.mpsas,
    required this.label,
    required this.color,
  });
  final double mpsas;
  final String label;
  final int color;
}

final Provider<DarknessCalculator> darknessCalculatorProvider = Provider<DarknessCalculator>((ProviderRef<DarknessCalculator> ref) {
  return DarknessCalculator();
});

final Provider<AsyncValue<DarknessState>> darknessProvider = Provider<AsyncValue<DarknessState>>((ProviderRef<AsyncValue<DarknessState>> ref) {
  final LightPollution lightPollution = ref.watch(lightPollutionProvider);
  final AsyncValue<AstronomyState> astronomyAsync = ref.watch(astronomyProvider);
  final DarknessCalculator calculator = ref.watch(darknessCalculatorProvider);

  return astronomyAsync.whenData((AstronomyState astronomy) {
    // Find Moon altitude
    // We need to find the Moon in the positions list
    // If not found, assume below horizon (0 altitude) or handle gracefully
    double moonAltitude = -90;
    
    for (final CelestialPosition pos in astronomy.positions) {
      if (pos.body == CelestialBody.moon) {
        moonAltitude = pos.altitude;
        break;
      }
    }

    final double effectiveMPSAS = calculator.calculateDarkness(
      baseMPSAS: lightPollution.mpsas,
      moonPhase: astronomy.moonPhaseInfo.illumination, // Using illumination as phase proxy (0.0-1.0)
      moonAltitude: moonAltitude,
    );

    final (String label, int color) = calculator.getDarknessLabel(effectiveMPSAS);

    return DarknessState(
      mpsas: effectiveMPSAS,
      label: label,
      color: color,
    );
  });
});
