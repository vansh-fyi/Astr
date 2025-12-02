import 'package:astr/features/astronomy/domain/services/astronomy_service.dart';
import 'package:astr/features/catalog/data/services/visibility_service_impl.dart';
import 'package:astr/features/catalog/domain/services/i_visibility_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final visibilityServiceProvider = Provider<IVisibilityService>((ref) {
  final astronomyService = ref.read(astronomyServiceProvider);
  return VisibilityServiceImpl(astronomyService);
});
