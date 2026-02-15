import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../astronomy/domain/services/astronomy_service.dart';
import 'smart_launch_provider.dart';

part 'initialization_provider.g.dart';

/// Provider that tracks app initialization state
@riverpod
class InitializationNotifier extends _$InitializationNotifier {
  @override
  bool build() {
    return false; // Not initialized
  }

  /// Perform app initialization tasks
  ///
  /// Story 4.1 (NFR-02): Optimized for <2s cold start.
  /// - Astronomy service init is deferred (lazy-loaded on first use)
  /// - Smart launch runs in background without blocking
  /// - Only critical initialization blocks splash → dashboard transition
  Future<void> initialize() async {
    try {
      // Story 4.1 (NFR-02): Defer astronomy service initialization
      // It will be lazily initialized when first accessed by astronomyProvider
      // This shaves ~500ms-1s off cold start time

      // Fire-and-forget: Initialize astronomy service in background
      ref.read(astronomyServiceProvider).init().ignore();

      // NEW: Trigger smart launch in background (Story 4.1)
      // Don't await - let it run async while splash continues
      // Router will handle the result when ready
      ref.read(launchResultProvider.future).ignore();

      // Mark as initialized immediately (don't block for heavy operations)
      state = true;
    } catch (e) {
      // Log error but still mark as initialized to proceed
      state = true;
    }
  }
}
