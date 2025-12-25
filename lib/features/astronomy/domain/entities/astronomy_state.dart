import 'celestial_position.dart';
import 'moon_phase_info.dart';

class AstronomyState {

  const AstronomyState({
    required this.moonPhaseInfo,
    this.positions = const <CelestialPosition>[],
  });

  factory AstronomyState.initial() {
    return const AstronomyState(
      moonPhaseInfo: MoonPhaseInfo(illumination: 0, phaseAngle: 0),
    );
  }
  final MoonPhaseInfo moonPhaseInfo;
  final List<CelestialPosition> positions;

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
