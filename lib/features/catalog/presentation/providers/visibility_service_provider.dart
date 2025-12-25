import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../astronomy/domain/services/astronomy_service.dart';
import '../../data/services/visibility_service_impl.dart';
import '../../domain/services/i_visibility_service.dart';

final Provider<IVisibilityService> visibilityServiceProvider = Provider<IVisibilityService>((ProviderRef<IVisibilityService> ref) {
  final AstronomyService astronomyService = ref.read(astronomyServiceProvider);
  return VisibilityServiceImpl(astronomyService);
});
