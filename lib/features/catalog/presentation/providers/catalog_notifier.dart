import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/celestial_type.dart';
import '../../domain/repositories/i_catalog_repository.dart';
import 'catalog_repository_provider.dart';

/// State for the catalog screen
class CatalogState {

  const CatalogState({
    required this.objects,
    required this.selectedType,
    this.isLoading = false,
    this.error,
  });
  final List<CelestialObject> objects;
  final CelestialType selectedType;
  final bool isLoading;
  final String? error;

  CatalogState copyWith({
    List<CelestialObject>? objects,
    CelestialType? selectedType,
    bool? isLoading,
    String? error,
  }) {
    return CatalogState(
      objects: objects ?? this.objects,
      selectedType: selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for catalog screen state
class CatalogNotifier extends StateNotifier<CatalogState> {

  CatalogNotifier(this._repository)
      : super(const CatalogState(
          objects: <CelestialObject>[],
          selectedType: CelestialType.planet,
          isLoading: true,
        )) {
    loadObjects(CelestialType.planet);
  }
  final ICatalogRepository _repository;

  /// Load objects for a specific type
  Future<void> loadObjects(CelestialType type) async {
    state = state.copyWith(isLoading: true, selectedType: type);

    final Either<Failure, List<CelestialObject>> result = await _repository.getObjectsByType(type);

    result.fold(
      (Failure failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (List<CelestialObject> objects) => state = state.copyWith(
        isLoading: false,
        objects: objects,
      ),
    );
  }

  /// Switch to a different category
  void switchCategory(CelestialType type) {
    if (state.selectedType != type) {
      loadObjects(type);
    }
  }
}

/// Provider for catalog notifier
final StateNotifierProvider<CatalogNotifier, CatalogState> catalogNotifierProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>((StateNotifierProviderRef<CatalogNotifier, CatalogState> ref) {
  final ICatalogRepository repository = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repository);
});
