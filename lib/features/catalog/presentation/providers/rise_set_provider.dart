import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweph/sweph.dart';

final riseSetProvider = FutureProvider.family<Map<String, DateTime?>, CelestialObject>((ref, object) async {
  final astronomyService = ref.watch(astronomyServiceProvider);
  final contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    return {'rise': null, 'set': null};
  }
  
  final astrContext = contextState.value!;
  final body = _mapToHeavenlyBody(object);
  
  if (body == null) {
    return {'rise': null, 'set': null};
  }

  try {
    return await astronomyService.calculateRiseSetTransit(
      body: body,
      starName: body == HeavenlyBody.SE_FIXSTAR ? object.name : null,
      date: astrContext.selectedDate,
      lat: astrContext.location!.latitude,
      long: astrContext.location!.longitude,
    );
  } catch (e) {
    return {'rise': null, 'set': null};
  }
});

HeavenlyBody? _mapToHeavenlyBody(CelestialObject object) {
  final name = object.name.toLowerCase();
  switch (name) {
    case 'sun': return HeavenlyBody.SE_SUN;
    case 'moon': return HeavenlyBody.SE_MOON;
    case 'mercury': return HeavenlyBody.SE_MERCURY;
    case 'venus': return HeavenlyBody.SE_VENUS;
    case 'mars': return HeavenlyBody.SE_MARS;
    case 'jupiter': return HeavenlyBody.SE_JUPITER;
    case 'saturn': return HeavenlyBody.SE_SATURN;
    case 'uranus': return HeavenlyBody.SE_URANUS;
    case 'neptune': return HeavenlyBody.SE_NEPTUNE;
    case 'pluto': return HeavenlyBody.SE_PLUTO;
    default:
      if (object.type == CelestialType.star) {
        return HeavenlyBody.SE_FIXSTAR;
      }
      return null;
  }
}
