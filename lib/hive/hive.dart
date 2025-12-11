import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

// Conditional import for path_provider (only on mobile platforms)
import 'hive_init_mobile.dart' if (dart.library.html) 'hive_init_web.dart';

import 'package:astr/features/profile/domain/entities/saved_location.dart';

import 'hive_registrar.g.dart';

Future<void> initHive() async {
  // Platform-specific initialization
  await initializeHivePlatform();

  // Open boxes
  await Hive.openBox<String>('prefs');
  await Hive.openBox('settings');
  await Hive.openBox<SavedLocation>('locations');
}
