import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/light_pollution.dart';
import 'visibility_provider.dart';

/// Provides the Light Pollution data.
///
/// Derives from [visibilityProvider] which manages the repository call and state.
final lightPollutionProvider = Provider<LightPollution>((ref) {
  final visibilityState = ref.watch(visibilityProvider);
  return visibilityState.lightPollution;
});
