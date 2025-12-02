import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweph/sweph.dart';

final highlightTimeProvider = FutureProvider.family<DateTime?, CelestialBody>((ref, body) async {
  final astronomyService = ref.watch(astronomyServiceProvider);
  final contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    return null;
  }
  
  final astrContext = contextState.value!;
  final heavenlyBody = _mapToHeavenlyBody(body);
  
  try {
    final times = await astronomyService.calculateRiseSetTransit(
      body: heavenlyBody,
      date: astrContext.selectedDate,
      lat: astrContext.location!.latitude,
      long: astrContext.location!.longitude,
    );
    return times['transit'];
  } catch (e) {
    return null;
  }
});

HeavenlyBody _mapToHeavenlyBody(CelestialBody body) {
  switch (body) {
    case CelestialBody.sun: return HeavenlyBody.SE_SUN;
    case CelestialBody.moon: return HeavenlyBody.SE_MOON;
    case CelestialBody.mercury: return HeavenlyBody.SE_MERCURY;
    case CelestialBody.venus: return HeavenlyBody.SE_VENUS;
    case CelestialBody.mars: return HeavenlyBody.SE_MARS;
    case CelestialBody.jupiter: return HeavenlyBody.SE_JUPITER;
    case CelestialBody.saturn: return HeavenlyBody.SE_SATURN;
    case CelestialBody.uranus: return HeavenlyBody.SE_URANUS;
    case CelestialBody.neptune: return HeavenlyBody.SE_NEPTUNE;
    case CelestialBody.pluto: return HeavenlyBody.SE_PLUTO;
  }
}
