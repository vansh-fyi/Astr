import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/dashboard/data/datasources/open_meteo_weather_service.dart';
import '../../features/dashboard/data/models/weather_cache_entry.dart';
import '../../features/dashboard/data/repositories/cached_weather_repository.dart';
import '../../features/dashboard/data/repositories/weather_repository_impl.dart';
import '../../features/dashboard/data/services/weather_background_sync_service.dart';
import '../../features/data_layer/models/zone_cache_entry.dart';
import '../../features/data_layer/repositories/cached_zone_repository.dart';
import '../../features/data_layer/services/h3_service.dart';
import '../../features/data_layer/services/remote_zone_service.dart';
import '../../features/profile/data/datasources/location_database_service.dart';
import '../../features/profile/data/repositories/location_repository_impl.dart';
import '../../hive/hive_registrar.g.dart';

/// Unique task name for weather sync.
const String kWeatherSyncTaskName = 'com.astr.weatherSync';

/// Unique task key for WorkManager.
const String kWeatherSyncTaskKey = 'weatherSyncTask';

/// WorkManager callback dispatcher.
///
/// This MUST be a top-level function (not a method).
/// Called by WorkManager when background task is triggered.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    debugPrint('WorkManager: Starting task $task');

    try {
      // Initialize Hive for background isolate
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapters();

      // Open required boxes
      await Hive.openBox<WeatherCacheEntry>('weatherCache');
      await Hive.openBox<ZoneCacheEntry>('zoneCache');

      // Initialize database
      final String dbPath = await getDatabasesPath();
      final LocationDatabaseService locationDb = LocationDatabaseService(
        testDatabasePath: '$dbPath/locations.db',
      );

      // Create H3 service
      final H3Service h3Service = H3Service();

      // Create location repository
      final LocationRepositoryImpl locationRepo = LocationRepositoryImpl(
        locationDb,
        h3Service,
      );

      // Create Dio for network requests
      final Dio dio = Dio();

      // Create OpenMeteoWeatherService
      final OpenMeteoWeatherService weatherService = OpenMeteoWeatherService(dio);

      // Create WeatherRepositoryImpl with dependencies
      final WeatherRepositoryImpl weatherRepoImpl = WeatherRepositoryImpl(weatherService);

      // Create weather repository with caching
      final CachedWeatherRepository weatherRepo = CachedWeatherRepository(
        innerRepository: weatherRepoImpl,
        cacheBox: Hive.box<WeatherCacheEntry>('weatherCache'),
        h3Service: h3Service,
      );

      // Create zone repository
      final RemoteZoneService remoteZoneService = RemoteZoneService();
      final CachedZoneRepository zoneRepo = CachedZoneRepository(
        remoteService: remoteZoneService,
        cacheBox: Hive.box<ZoneCacheEntry>('zoneCache'),
      );

      // Create sync service
      final WeatherBackgroundSyncService syncService = WeatherBackgroundSyncService(
        weatherRepository: weatherRepo,
        locationRepository: locationRepo,
        zoneRepository: zoneRepo,
        h3Service: h3Service,
      );

      // Perform sync
      final int syncedCount = await syncService.syncActiveLocations();

      debugPrint('WorkManager: Synced $syncedCount locations');

      return true; // Success
    } catch (e, st) {
      debugPrint('WorkManager: Error: $e');
      debugPrint('Stack trace: $st');
      return false; // Failure (will retry)
    }
  });
}

/// Registers background sync with WorkManager.
///
/// Call this from main.dart during app initialization.
/// Safe to call multiple times - won't create duplicate tasks.
Future<void> initializeBackgroundSync() async {
  // BGTaskScheduler throws a native NSException on the iOS Simulator
  // that cannot be caught by Dart try-catch, causing a crash (SIGABRT).
  // Skip registration entirely on the simulator.
  if (Platform.isIOS) {
    final IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
    if (!deviceInfo.isPhysicalDevice) {
      debugPrint('Background sync: Skipping on iOS Simulator');
      return;
    }
  }

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Schedule periodic background sync (once per day)
    await Workmanager().registerPeriodicTask(
      kWeatherSyncTaskName,
      kWeatherSyncTaskKey,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected, // Require network
        requiresBatteryNotLow: true, // Skip if battery critical
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Don't replace existing
    );

    debugPrint('Background sync: WorkManager initialized');
  } catch (e) {
    // Silent fail - background sync is best-effort
    debugPrint('Background sync: Failed to initialize WorkManager: $e');
  }
}

/// Cancels all scheduled background sync tasks.
///
/// Useful for testing or when user opts out.
Future<void> cancelBackgroundSync() async {
  try {
    await Workmanager().cancelByUniqueName(kWeatherSyncTaskName);
    debugPrint('Background sync: Cancelled');
  } catch (e) {
    debugPrint('Background sync: Failed to cancel: $e');
  }
}
