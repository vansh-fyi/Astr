import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../astronomy/domain/services/astronomy_service.dart';

part 'initialization_provider.g.dart';

/// Provider that tracks app initialization state
@riverpod
class InitializationNotifier extends _$InitializationNotifier {
  @override
  bool build() {
    return false; // Not initialized
  }

  /// Perform app initialization tasks
  Future<void> initialize() async {
    try {
      // Initialize Astronomy Service (Swiss Ephemeris)
      await ref.read(astronomyServiceProvider).init();

      // Mark as initialized
      state = true;
    } catch (e) {
      // Log error but still mark as initialized to proceed
      state = true;
    }
  }
}
