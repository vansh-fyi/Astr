// lib/hive/hive_adapters.dart   ← keep registrar but REMOVE the spec
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../config/theme/theme_ui_model.dart';
// WeatherCacheEntry has its own @HiveType annotation so it generates its own adapter
// import '../features/dashboard/data/models/weather_cache_entry.dart';
// import '../features/authentication/domain/login_request.dart';

// ignore: always_specify_types
@GenerateAdapters(firstTypeId: 0,[
  // AdapterSpec<LoginCredentials>(),
  AdapterSpec<ThemeUiModel>(),
  // WeatherCacheEntry removed - it has its own @HiveType(typeId: 2) annotation
  // Add other models here
])           // or just omit the list entirely
part 'hive_adapters.g.dart';

