import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/astro_engine_impl.dart';
import '../../domain/repositories/i_astro_engine.dart';

final Provider<IAstroEngine> astroEngineProvider = Provider<IAstroEngine>((ProviderRef<IAstroEngine> ref) {
  return AstroEngineImpl();
});
