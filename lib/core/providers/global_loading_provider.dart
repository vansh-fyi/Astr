import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/astronomy/domain/entities/astronomy_state.dart';
import '../../features/astronomy/presentation/providers/astronomy_provider.dart';
import '../../features/context/domain/entities/astr_context.dart';
import '../../features/context/presentation/providers/astr_context_provider.dart';
import '../../features/dashboard/domain/entities/weather.dart';
import '../../features/dashboard/presentation/providers/weather_provider.dart';

final Provider<bool> globalLoadingProvider = Provider<bool>((ProviderRef<bool> ref) {
  final AsyncValue<AstrContext> contextAsync = ref.watch(astrContextProvider);
  final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
  final AsyncValue<AstronomyState> astronomyAsync = ref.watch(astronomyProvider);

  return contextAsync.isLoading || weatherAsync.isLoading || astronomyAsync.isLoading;
});
