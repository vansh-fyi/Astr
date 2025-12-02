import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/context/presentation/providers/astr_context_provider.dart';
import '../../features/dashboard/presentation/providers/weather_provider.dart';
import '../../features/astronomy/presentation/providers/astronomy_provider.dart';

final globalLoadingProvider = Provider<bool>((ref) {
  final contextAsync = ref.watch(astrContextProvider);
  final weatherAsync = ref.watch(weatherProvider);
  final astronomyAsync = ref.watch(astronomyProvider);

  return contextAsync.isLoading || weatherAsync.isLoading || astronomyAsync.isLoading;
});
