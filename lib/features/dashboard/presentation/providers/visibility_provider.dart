import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../data/datasources/png_map_service.dart';
import '../../data/repositories/light_pollution_repository.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';

// Services
final Provider<PngMapService> pngMapServiceProvider = Provider((ProviderRef<PngMapService> ref) => PngMapService());

// Repository - Uses PNG Light Pollution Atlas only (removed VIIRS API)
final Provider<ILightPollutionService> lightPollutionRepositoryProvider = Provider<ILightPollutionService>((ProviderRef<ILightPollutionService> ref) {
  return LightPollutionRepository(
    ref.watch(pngMapServiceProvider),
  );
});

// State
class VisibilityState {

  const VisibilityState({
    required this.lightPollution,
    this.isLoading = false,
    this.error,
  });

  factory VisibilityState.initial() => VisibilityState(lightPollution: LightPollution.unknown());
  final LightPollution lightPollution;
  final bool isLoading;
  final String? error;

  VisibilityState copyWith({
    LightPollution? lightPollution,
    bool? isLoading,
    String? error,
  }) {
    return VisibilityState(
      lightPollution: lightPollution ?? this.lightPollution,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class VisibilityNotifier extends StateNotifier<VisibilityState> {

  VisibilityNotifier(this._repository) : super(VisibilityState.initial());
  final ILightPollutionService _repository;

  Future<void> fetchData(GeoLocation location) async {
    // Avoid unnecessary fetches if loading
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true);

    final Either<Failure, LightPollution> result = await _repository.getLightPollution(location);

    result.fold(
      (Failure failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (LightPollution data) => state = state.copyWith(isLoading: false, lightPollution: data),
    );
  }
}

final StateNotifierProvider<VisibilityNotifier, VisibilityState> visibilityProvider = StateNotifierProvider<VisibilityNotifier, VisibilityState>((StateNotifierProviderRef<VisibilityNotifier, VisibilityState> ref) {
  final ILightPollutionService repository = ref.watch(lightPollutionRepositoryProvider);
  final VisibilityNotifier notifier = VisibilityNotifier(repository);

  // Listen to location changes
  final AsyncValue<AstrContext> astrContextAsync = ref.watch(astrContextProvider);
  
  astrContextAsync.whenData((AstrContext context) {
    // When we have a valid location, fetch data
    // We use a microtask or similar to avoid "setState during build" if strictly needed,
    // but usually calling a method on the notifier is safe here if it doesn't trigger immediate side-effects during build.
    // However, to be safe and avoid loops, we can check if data is already loaded for this location?
    // For simplicity in this MVP, we just trigger fetch.
    // Ideally, we should compare with previous location or state.
    
    // NOTE: In a real app, we'd want to avoid re-fetching if location hasn't changed significantly.
    // For now, we rely on the provider rebuilding the notifier if dependencies change? 
    // Actually, StateNotifierProvider keeps the notifier alive. 
    // We should use `ref.listen` or just trigger it here.
    
    // Better pattern: Use a separate provider for the "Future" and let the notifier just hold state?
    // Or just call it.
    
    Future.microtask(() => notifier.fetchData(context.location));
  });

  return notifier;
});
