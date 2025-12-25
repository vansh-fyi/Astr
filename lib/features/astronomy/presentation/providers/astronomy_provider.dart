import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';
import 'package:riverpod/src/async_notifier.dart';

import '../../../../core/error/failure.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/astronomy_state.dart';
import '../../domain/entities/celestial_body.dart';
import '../../domain/entities/celestial_position.dart';
import '../../domain/entities/moon_phase_info.dart';
import '../../domain/repositories/i_astro_engine.dart';
import 'astro_engine_provider.dart';

class AstronomyNotifier extends AsyncNotifier<AstronomyState> {
  @override
  Future<AstronomyState> build() async {
    final AsyncValue<AstrContext> contextState = ref.watch(astrContextProvider);
    
    return contextState.when(
      data: (AstrContext context) async {
        final IAstroEngine engine = ref.read(astroEngineProvider);
        
        // 1. Get Moon Phase Info
        final Either<Failure, MoonPhaseInfo> moonResult = await engine.getMoonPhaseInfo(time: context.selectedDate);
        final MoonPhaseInfo moonPhaseInfo = moonResult.fold(
          (Failure failure) => const MoonPhaseInfo(illumination: 0, phaseAngle: 0),
          (MoonPhaseInfo info) => info,
        );

        // 2. Get Positions for all bodies
        final List<CelestialPosition> positions = <CelestialPosition>[];
        for (final CelestialBody body in CelestialBody.values) {
          final Either<Failure, CelestialPosition> result = await engine.getPosition(
            body: body,
            time: context.selectedDate,
            latitude: context.location.latitude,
            longitude: context.location.longitude,
          );
          
          result.fold(
            (Failure failure) {
              // Log failure or ignore
            },
            positions.add,
          );
        }

        return AstronomyState(
          moonPhaseInfo: moonPhaseInfo,
          positions: positions,
        );
      },
      loading: AstronomyState.initial,
      error: (_, __) => AstronomyState.initial(),
    );
  }
}

final AsyncNotifierProviderImpl<AstronomyNotifier, AstronomyState> astronomyProvider = AsyncNotifierProvider<AstronomyNotifier, AstronomyState>(() {
  return AstronomyNotifier();
});
