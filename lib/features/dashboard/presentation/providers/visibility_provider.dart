import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../data/datasources/png_map_service.dart';
import '../../data/repositories/light_pollution_repository.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';
import '../../../../features/context/domain/entities/geo_location.dart';

// Services
final pngMapServiceProvider = Provider((ref) => PngMapService());

// Repository - Uses PNG Light Pollution Atlas only (removed VIIRS API)
final lightPollutionRepositoryProvider = Provider<ILightPollutionService>((ref) {
  return LightPollutionRepository(
    ref.watch(pngMapServiceProvider),
  );
});

// State
class VisibilityState {
  final LightPollution lightPollution;
  final bool isLoading;
  final String? error;

  const VisibilityState({
    required this.lightPollution,
    this.isLoading = false,
    this.error,
  });

  factory VisibilityState.initial() => VisibilityState(lightPollution: LightPollution.unknown());

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
  final ILightPollutionService _repository;

  VisibilityNotifier(this._repository) : super(VisibilityState.initial());

  Future<void> fetchData(GeoLocation location) async {
    // Avoid unnecessary fetches if loading
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true);

    final result = await _repository.getLightPollution(location);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) => state = state.copyWith(isLoading: false, lightPollution: data),
    );
  }
}

final visibilityProvider = StateNotifierProvider<VisibilityNotifier, VisibilityState>((ref) {
  final repository = ref.watch(lightPollutionRepositoryProvider);
  final notifier = VisibilityNotifier(repository);

  // Listen to location changes
  final astrContextAsync = ref.watch(astrContextProvider);
  
  astrContextAsync.whenData((context) {
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
