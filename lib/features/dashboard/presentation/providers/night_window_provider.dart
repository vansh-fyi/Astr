import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../astronomy/domain/services/astronomy_service.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';

final FutureProvider<Map<String, DateTime>> nightWindowProvider = FutureProvider<Map<String, DateTime>>((FutureProviderRef<Map<String, DateTime>> ref) async {
  final AstronomyService astronomyService = ref.watch(astronomyServiceProvider);
  final AsyncValue<AstrContext> contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    // Return default window if context not ready (e.g. now to now+12h)
    final DateTime now = DateTime.now();
    return <String, DateTime>{'start': now, 'end': now.add(const Duration(hours: 12))};
  }
  
  final AstrContext astrContext = contextState.value!;
  
  return astronomyService.getNightWindow(
    date: astrContext.selectedDate,
    lat: astrContext.location.latitude,
    long: astrContext.location.longitude,
  );
});
