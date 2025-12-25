import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/repositories/i_catalog_repository.dart';

/// Provider for catalog repository
final Provider<ICatalogRepository> catalogRepositoryProvider = Provider<ICatalogRepository>((ProviderRef<ICatalogRepository> ref) {
  return CatalogRepositoryImpl();
});
