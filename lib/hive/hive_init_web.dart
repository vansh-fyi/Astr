// Web platform Hive initialization
import 'package:hive_ce/hive.dart';
import 'hive_registrar.g.dart';

Future<void> initializeHivePlatform() async {
  // Web doesn't need path initialization
  Hive.registerAdapters();
}
