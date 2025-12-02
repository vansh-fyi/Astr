import 'package:astr/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:astr/features/catalog/domain/repositories/i_catalog_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for catalog repository
final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  return CatalogRepositoryImpl();
});
