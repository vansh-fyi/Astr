import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/darkness_calculator.dart';
import '../../../astronomy/presentation/providers/astronomy_provider.dart';
import 'light_pollution_provider.dart';

class DarknessState {
  final double mpsas;
  final String label;
  final int color;

  const DarknessState({
    required this.mpsas,
    required this.label,
    required this.color,
  });
}

final darknessCalculatorProvider = Provider<DarknessCalculator>((ref) {
  return DarknessCalculator();
});

final darknessProvider = Provider<AsyncValue<DarknessState>>((ref) {
  final lightPollution = ref.watch(lightPollutionProvider);
  final astronomyAsync = ref.watch(astronomyProvider);
  final calculator = ref.watch(darknessCalculatorProvider);

  return astronomyAsync.whenData((astronomy) {
    // Find Moon altitude
    // We need to find the Moon in the positions list
    // If not found, assume below horizon (0 altitude) or handle gracefully
    double moonAltitude = -90.0;
    
    for (final pos in astronomy.positions) {
      if (pos.body == CelestialBody.moon) {
        moonAltitude = pos.altitude;
        break;
      }
    }

    final effectiveMPSAS = calculator.calculateDarkness(
      baseMPSAS: lightPollution.mpsas,
      moonPhase: astronomy.moonPhaseInfo.illumination, // Using illumination as phase proxy (0.0-1.0)
      moonAltitude: moonAltitude,
    );

    final (label, color) = calculator.getDarknessLabel(effectiveMPSAS);

    return DarknessState(
      mpsas: effectiveMPSAS,
      label: label,
      color: color,
    );
  });
});
