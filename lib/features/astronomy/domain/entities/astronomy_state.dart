import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';

class AstronomyState {
  final MoonPhaseInfo moonPhaseInfo;
  final List<CelestialPosition> positions;

  const AstronomyState({
    required this.moonPhaseInfo,
    this.positions = const [],
  });

  factory AstronomyState.initial() {
    return const AstronomyState(
      moonPhaseInfo: MoonPhaseInfo(illumination: 0.0, phaseAngle: 0.0),
      positions: [],
    );
  }

  AstronomyState copyWith({
    MoonPhaseInfo? moonPhaseInfo,
    List<CelestialPosition>? positions,
  }) {
    return AstronomyState(
      moonPhaseInfo: moonPhaseInfo ?? this.moonPhaseInfo,
      positions: positions ?? this.positions,
    );
  }
}
