import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/entities/celestial_position.dart';
import 'package:astr/features/astronomy/domain/entities/moon_phase_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/astronomy_state.dart';
import 'astro_engine_provider.dart';

class AstronomyNotifier extends AsyncNotifier<AstronomyState> {
  @override
  Future<AstronomyState> build() async {
    final contextState = ref.watch(astrContextProvider);
    
    return contextState.when(
      data: (context) async {
        final engine = ref.read(astroEngineProvider);
        
        // 1. Get Moon Phase Info
        final moonResult = await engine.getMoonPhaseInfo(time: context.selectedDate);
        final moonPhaseInfo = moonResult.fold(
          (failure) => const MoonPhaseInfo(illumination: 0.0, phaseAngle: 0.0),
          (info) => info,
        );

        // 2. Get Positions for all bodies
        final List<CelestialPosition> positions = [];
        for (final body in CelestialBody.values) {
          final result = await engine.getPosition(
            body: body,
            time: context.selectedDate,
            latitude: context.location.latitude,
            longitude: context.location.longitude,
          );
          
          result.fold(
            (failure) {
              // Log failure or ignore
            },
            (position) {
              positions.add(position);
            },
          );
        }

        return AstronomyState(
          moonPhaseInfo: moonPhaseInfo,
          positions: positions,
        );
      },
      loading: () => AstronomyState.initial(),
      error: (_, __) => AstronomyState.initial(),
    );
  }
}

final astronomyProvider = AsyncNotifierProvider<AstronomyNotifier, AstronomyState>(() {
  return AstronomyNotifier();
});
