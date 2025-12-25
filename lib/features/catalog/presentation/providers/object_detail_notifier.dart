import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/repositories/i_catalog_repository.dart';
import 'catalog_repository_provider.dart';

/// State for object detail screen
class ObjectDetailState {

  const ObjectDetailState({
    this.object,
    this.isLoading = false,
    this.error,
  });
  final CelestialObject? object;
  final bool isLoading;
  final String? error;

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
final StateNotifierProviderFamily<ObjectDetailNotifier, ObjectDetailState, String> objectDetailNotifierProvider =
    StateNotifierProvider.family<ObjectDetailNotifier, ObjectDetailState, String>(
  (StateNotifierProviderRef<ObjectDetailNotifier, ObjectDetailState> ref, String objectId) {
    final ICatalogRepository repository = ref.read(catalogRepositoryProvider);
    return ObjectDetailNotifier(repository, ref, objectId);
  },
);

/// Notifier for object detail screen
class ObjectDetailNotifier extends StateNotifier<ObjectDetailState> {

  ObjectDetailNotifier(
    this._repository,
    this._ref,
    this.objectId,
  ) : super(const ObjectDetailState(isLoading: true)) {
    loadObject();
  }
  final ICatalogRepository _repository;
  final Ref _ref;
  final String objectId;

  /// Load object by ID
  Future<void> loadObject() async {
    state = state.copyWith(isLoading: true);

    final Either<Failure, CelestialObject> result = await _repository.getObjectById(objectId);

    result.fold(
      (Failure failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (CelestialObject object) {
        state = state.copyWith(
          isLoading: false,
          object: object,
        );
      },
    );
  }
}
