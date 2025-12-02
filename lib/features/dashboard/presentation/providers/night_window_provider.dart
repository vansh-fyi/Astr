import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nightWindowProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  final astronomyService = ref.watch(astronomyServiceProvider);
  final contextState = ref.watch(astrContextProvider);
  
  if (!contextState.hasValue) {
    // Return default window if context not ready (e.g. now to now+12h)
    final now = DateTime.now();
    return {'start': now, 'end': now.add(const Duration(hours: 12))};
  }
  
  final astrContext = contextState.value!;
  
  return await astronomyService.getNightWindow(
    date: astrContext.selectedDate,
    lat: astrContext.location!.latitude,
    long: astrContext.location!.longitude,
  );
});
