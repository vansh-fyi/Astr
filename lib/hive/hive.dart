import 'package:hive_ce/hive.dart';

import '../features/profile/domain/entities/saved_location.dart';
// Conditional import for path_provider (only on mobile platforms)
import 'hive_init_mobile.dart' if (dart.library.html) 'hive_init_web.dart';

Future<void> initHive() async {
  // Platform-specific initialization
  await initializeHivePlatform();

  // Open boxes
  await Hive.openBox<String>('prefs');
  await Hive.openBox('settings');
  await Hive.openBox<SavedLocation>('locations');
}
