// Platform-specific initialization for mobile (iOS, Android, macOS, etc.)
import 'dart:io';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> initializePlatformSpecific() async {
  // Set high refresh rate on Android devices
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      // Ignore if not supported
    }
  }
}
