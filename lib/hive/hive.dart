import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:astr/features/profile/domain/entities/saved_location.dart';

import 'hive_registrar.g.dart';

Future<void> initHive() async {
  if (!kIsWeb) {
    final Directory directory = await getTemporaryDirectory();
    Hive
      ..init(directory.path)
      ..registerAdapters();
  }
  await Hive.openBox<String>('prefs');
  await Hive.openBox('settings');
  await Hive.openBox<SavedLocation>('locations');
}
