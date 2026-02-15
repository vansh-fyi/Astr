import 'package:flutter/material.dart';

/// Service for displaying toast notifications (SnackBars).
///
/// Provides standardized toast messages for error feedback, particularly
/// for GPS failures as specified in Story 4.1 (NFR-10).
///
/// **UX Guidelines:**
/// - Non-blocking (SnackBarBehavior.floating)
/// - High contrast (4.5:1 minimum)
/// - OLED-friendly (dark background)
/// - Red Mode compatible (uses Theme colors)
class ToastService {
  /// Shows a generic error toast with the given message.
  ///
  /// Parameters:
  /// - [context]: BuildContext for ScaffoldMessenger
  /// - [message]: Error message to display
  ///
  /// **Styling:**
  /// - Uses Theme.of(context).colorScheme.error for background
  /// - Bold text for Red Mode compliance (NFR-11)
  /// - Floating behavior (non-blocking)
  /// - 4-second duration
  /// - Dismissible with action button
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // NFR-11: Bold in Red Mode
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows the GPS timeout toast (NFR-10).
  ///
  /// Displays the specific message: "GPS Unavailable. Restart or hit Refresh."
  ///
  /// Parameters:
  /// - [context]: BuildContext for ScaffoldMessenger
  ///
  /// **Use Case:**
  /// When DeviceLocationService returns TimeoutFailure after 10 seconds,
  /// SmartLaunchController returns LaunchTimeout, and HomeScreen should
  /// call this method to inform the user.
  static void showGPSTimeout(BuildContext context) {
    // NFR-10: Specific GPS timeout message
    showError(context, 'GPS Unavailable. Restart or hit Refresh.');
  }

  /// Shows a success toast with the given message.
  ///
  /// Parameters:
  /// - [context]: BuildContext for ScaffoldMessenger
  /// - [message]: Success message to display
  ///
  /// **Styling:**
  /// - Uses Theme.of(context).colorScheme.primary for background
  /// - Floating behavior (non-blocking)
  /// - 3-second duration
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an info toast with the given message.
  ///
  /// Parameters:
  /// - [context]: BuildContext for ScaffoldMessenger
  /// - [message]: Info message to display
  ///
  /// **Styling:**
  /// - Uses Theme.of(context).colorScheme.surface for background
  /// - Floating behavior (non-blocking)
  /// - 3-second duration
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
