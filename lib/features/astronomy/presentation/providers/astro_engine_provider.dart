import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_astro_engine.dart';
import '../../data/repositories/astro_engine_impl.dart';

final astroEngineProvider = Provider<IAstroEngine>((ref) {
  return AstroEngineImpl();
});
