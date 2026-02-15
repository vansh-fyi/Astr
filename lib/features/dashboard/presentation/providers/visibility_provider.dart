import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../../../features/context/presentation/providers/astr_context_provider.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../data_layer/providers/cached_zone_repository_provider.dart';
import '../../../data_layer/repositories/cached_zone_repository.dart';
import '../../../data_layer/services/h3_service.dart';
import '../../data/repositories/light_pollution_repository.dart';
import '../../domain/entities/light_pollution.dart';
import '../../domain/repositories/i_light_pollution_service.dart';

// Repository - Uses CachedZoneRepository (remote API + Hive cache)
// Dark sky locations (not in database) return Bortle 1 default
final Provider<ILightPollutionService> lightPollutionRepositoryProvider = Provider<ILightPollutionService>((Ref ref) {
  final CachedZoneRepository zoneRepository = ref.watch(cachedZoneRepositoryProvider);
  final H3Service h3Service = ref.watch(h3ServiceProvider);
  
  return LightPollutionRepository(
    zoneRepository: zoneRepository,
    h3Service: h3Service,
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

final StateNotifierProvider<VisibilityNotifier, VisibilityState> visibilityProvider = StateNotifierProvider<VisibilityNotifier, VisibilityState>((Ref ref) {
  final ILightPollutionService repository = ref.watch(lightPollutionRepositoryProvider);
  final VisibilityNotifier notifier = VisibilityNotifier(repository);

  // Listen to location changes
  final AsyncValue<AstrContext> astrContextAsync = ref.watch(astrContextProvider);
  
  astrContextAsync.whenData((AstrContext context) {
    // When we have a valid location, fetch data
    Future<void>.microtask(() => notifier.fetchData(context.location));
  });

  return notifier;
});
