import 'package:astr/core/error/failure.dart';
import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:astr/features/catalog/presentation/providers/catalog_repository_provider.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for object detail screen
class ObjectDetailState {
  final CelestialObject? object;
  final bool isLoading;
  final String? error;

  const ObjectDetailState({
    this.object,
    this.isLoading = false,
    this.error,
  });

  ObjectDetailState copyWith({
    CelestialObject? object,
    bool? isLoading,
    String? error,
  }) {
    return ObjectDetailState(
      object: object ?? this.object,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for object detail notifier
final objectDetailNotifierProvider =
    StateNotifierProvider.family<ObjectDetailNotifier, ObjectDetailState, String>(
  (ref, objectId) {
    final repository = ref.read(catalogRepositoryProvider);
    return ObjectDetailNotifier(repository, ref, objectId);
  },
);

/// Notifier for object detail screen
class ObjectDetailNotifier extends StateNotifier<ObjectDetailState> {
  final ICatalogRepository _repository;
  final Ref _ref;
  final String objectId;

  ObjectDetailNotifier(
    this._repository,
    this._ref,
    this.objectId,
  ) : super(const ObjectDetailState(isLoading: true)) {
    loadObject();
  }

  /// Load object by ID
  Future<void> loadObject() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getObjectById(objectId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (object) {
        state = state.copyWith(
          isLoading: false,
          object: object,
          error: null,
        );
      },
    );
  }
}
