import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';

import '../../../../core/error/failure.dart';
import '../../../astronomy/domain/services/astronomy_service.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/visibility_graph_data.dart';
import '../../domain/services/i_visibility_service.dart';
import 'object_detail_notifier.dart';
import 'visibility_service_provider.dart';

/// State for visibility graph
class VisibilityGraphState {

  const VisibilityGraphState({
    this.graphData,
    this.isLoading = false,
    this.error,
  });
  final VisibilityGraphData? graphData;
  final bool isLoading;
  final String? error;

  VisibilityGraphState copyWith({
    VisibilityGraphData? graphData,
    bool? isLoading,
    String? error,
  }) {
    return VisibilityGraphState(
      graphData: graphData ?? this.graphData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for visibility graph data
class VisibilityGraphNotifier extends StateNotifier<VisibilityGraphState> {

  VisibilityGraphNotifier(
    this._visibilityService,
    this._astronomyService,
    this._ref,
    this.objectId,
    this._object,
  ) : super(const VisibilityGraphState(isLoading: true)) {
    calculateGraph();
  }
  final IVisibilityService _visibilityService;
  final Ref _ref;
  final String objectId;
  final CelestialObject? _object;

  final AstronomyService _astronomyService;

  /// Calculate visibility graph data
  Future<void> calculateGraph() async {
    state = state.copyWith(isLoading: true);

    // Use the passed object
    final CelestialObject? object = _object;

    if (object == null) {
      // If object is null, it might be loading or not found.
      // We can check if the provider is loading, but since we are watching it in the provider,
      // this notifier will be re-created when it loads.
      // So if it's null here, it's either truly not found or still loading initial state.
      // Let's assume loading if we don't have it yet, or "Object not found" if we want to be strict.
      // But since we re-create on change, let's set error "Object not found" only if we are sure.
      // Actually, if we are re-created, we start fresh.
      state = state.copyWith(
        isLoading: false,
        error: 'Object not found',
      );
      return;
    }

    try {
      // Wait for context to be loaded
      final AstrContext context = await _ref.read(astrContextProvider.future);

      // Calculate night window
      final Map<String, DateTime> nightWindow = await _astronomyService.getNightWindow(
        date: context.selectedDate,
        lat: context.location.latitude,
        long: context.location.longitude,
      );

      // Calculate visibility graph
      final Either<Failure, VisibilityGraphData> result = await _visibilityService.calculateVisibility(
        object: object,
        location: context.location,
        startTime: nightWindow['start']!, // Use calculated night start
        endTime: nightWindow['end'], // Use calculated night end
      );

      result.fold(
        (Failure failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (VisibilityGraphData graphData) => state = state.copyWith(
          isLoading: false,
          graphData: graphData,
        ),
      );
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get context: $err',
      );
    }
  }

  /// Refresh graph data (e.g., when user changes location or time)
  Future<void> refresh() async {
    await calculateGraph();
  }
}

/// Provider for visibility graph notifier
/// Family provider to support multiple objects
final StateNotifierProviderFamily<VisibilityGraphNotifier, VisibilityGraphState, String> visibilityGraphProvider =
    StateNotifierProvider.family<VisibilityGraphNotifier, VisibilityGraphState, String>(
  (StateNotifierProviderRef<VisibilityGraphNotifier, VisibilityGraphState> ref, String objectId) {
    final IVisibilityService visibilityService = ref.read(visibilityServiceProvider);
    // Watch context to trigger rebuild when location/date changes
    ref.watch(astrContextProvider);
    
    final AstronomyService astronomyService = ref.read(astronomyServiceProvider);
    
    // Watch object detail to trigger rebuild when object is loaded
    final ObjectDetailState objectState = ref.watch(objectDetailNotifierProvider(objectId));
    
    return VisibilityGraphNotifier(visibilityService, astronomyService, ref, objectId, objectState.object);
  },
);