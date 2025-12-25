import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/light_pollution.dart';
import 'visibility_provider.dart';

/// Provides the Light Pollution data.
///
/// Derives from [visibilityProvider] which manages the repository call and state.
final Provider<LightPollution> lightPollutionProvider = Provider<LightPollution>((ProviderRef<LightPollution> ref) {
  final VisibilityState visibilityState = ref.watch(visibilityProvider);
  return visibilityState.lightPollution;
});
