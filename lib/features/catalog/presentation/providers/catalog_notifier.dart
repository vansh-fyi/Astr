import 'package:astr/features/catalog/domain/entities/celestial_object.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:astr/features/catalog/presentation/providers/catalog_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the catalog screen
class CatalogState {
  final List<CelestialObject> objects;
  final CelestialType selectedType;
  final bool isLoading;
  final String? error;

  const CatalogState({
    required this.objects,
    required this.selectedType,
    this.isLoading = false,
    this.error,
  });

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
  final ICatalogRepository _repository;

  CatalogNotifier(this._repository)
      : super(const CatalogState(
          objects: [],
          selectedType: CelestialType.planet,
          isLoading: true,
        )) {
    loadObjects(CelestialType.planet);
  }

  /// Load objects for a specific type
  Future<void> loadObjects(CelestialType type) async {
    state = state.copyWith(isLoading: true, selectedType: type);

    final result = await _repository.getObjectsByType(type);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (objects) => state = state.copyWith(
        isLoading: false,
        objects: objects,
        error: null,
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
final catalogNotifierProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repository);
});
