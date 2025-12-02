import 'package:astr/features/catalog/domain/entities/visibility_graph_data.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/graph_point.dart';
import 'package:astr/features/catalog/domain/services/i_visibility_service.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/features/catalog/presentation/providers/visibility_service_provider.dart';
import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

/// State for visibility graph
class VisibilityGraphState {
  final VisibilityGraphData? graphData;
  final bool isLoading;
  final String? error;

  const VisibilityGraphState({
    this.graphData,
    this.isLoading = false,
    this.error,
  });

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
  final IVisibilityService _visibilityService;
  final Ref _ref;
  final String objectId;
  final CelestialObject? _object;

  final AstronomyService _astronomyService;

  VisibilityGraphNotifier(
    this._visibilityService,
    this._astronomyService,
    this._ref,
    this.objectId,
    this._object,
  ) : super(const VisibilityGraphState(isLoading: true)) {
    calculateGraph();
  }

  /// Calculate visibility graph data
  Future<void> calculateGraph() async {
    state = state.copyWith(isLoading: true, error: null);

    // Use the passed object
    final object = _object;

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
      final context = await _ref.read(astrContextProvider.future);

      // Calculate night window
      final nightWindow = await _astronomyService.getNightWindow(
        date: context.selectedDate,
        lat: context.location.latitude,
        long: context.location.longitude,
      );

      // Calculate visibility graph
      final result = await _visibilityService.calculateVisibility(
        object: object,
        location: context.location,
        startTime: nightWindow['start']!, // Use calculated night start
        endTime: nightWindow['end'], // Use calculated night end
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (graphData) => state = state.copyWith(
          isLoading: false,
          graphData: graphData,
          error: null,
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
final visibilityGraphProvider =
    StateNotifierProvider.family<VisibilityGraphNotifier, VisibilityGraphState, String>(
  (ref, objectId) {
    final visibilityService = ref.read(visibilityServiceProvider);
    // Watch context to trigger rebuild when location/date changes
    ref.watch(astrContextProvider);
    
    final astronomyService = ref.read(astronomyServiceProvider);
    
    // Watch object detail to trigger rebuild when object is loaded
    final objectState = ref.watch(objectDetailNotifierProvider(objectId));
    
    return VisibilityGraphNotifier(visibilityService, astronomyService, ref, objectId, objectState.object);
  },
);