// ignore_for_file: always_put_control_body_on_new_line

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:timezone/data/latest.dart' as tz;

import 'constants/strings.dart';
import 'core/platform/background_sync_handler.dart';
import 'features/dashboard/data/models/weather_cache_entry.dart';
import 'features/dashboard/data/services/weather_cache_pruning_service.dart';
import 'hive/hive.dart';
// Platform-specific imports - only import on non-web platforms
import 'main_mobile.dart' if (dart.library.html) 'main_web.dart';
import 'my_app.dart';

/// Try using const constructors as much as possible!

void main() async {
  /// Initialize packages
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await EasyLocalization.ensureInitialized();
  await initHive();

  // FR-10: Prune old cache entries on app start (fire-and-forget)
  _pruneOldCacheEntries();

  // Story 3.4: Initialize background sync (WorkManager/BGTaskScheduler)
  initializeBackgroundSync();

  // await AstroEngineImpl.initialize(); // Disabled for visual testing
  await setPreferredOrientations();

  // Platform-specific initialization (Android high refresh rate, etc.)
  await initializePlatformSpecific();

  // Astronomy Service initialization now handled by SplashScreen
  final ProviderContainer container = ProviderContainer();

  if (kReleaseMode) {
    /// Disable debugPrint in release mode
    /// This will prevent any debugPrint statements from being executed
    /// and will not print anything to the console.
    /// You can also use a custom implementation if needed
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Configure Microsoft Clarity
  final ClarityConfig clarityConfig = ClarityConfig(
    projectId: 'ujfp0i4u4p',
    logLevel: LogLevel.None, // Use LogLevel.Verbose for debugging
  );

  runApp(
    ClarityWidget(
      clarityConfig: clarityConfig,
      app: UncontrolledProviderScope(
        container: container,
        child: EasyLocalization(
          supportedLocales: const <Locale>[
            /// Add your supported locales here
            Locale('en'),
            Locale('tr'),
          ],
          path: Strings.localizationsPath,
          fallbackLocale: const Locale('en'),
          child: const MyApp(),
        ),
      ),
    ),
  );

  /// Add this line to get the error stack trace in release mode
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
}

/// Prunes old cache entries on app start (FR-10).
///
/// Uses fire-and-forget pattern to avoid blocking app startup.
void _pruneOldCacheEntries() {
  try {
    final Box<WeatherCacheEntry> cacheBox = Hive.box<WeatherCacheEntry>('weatherCache');
    final WeatherCachePruningService pruningService = WeatherCachePruningService(
      cacheBox: cacheBox,
    );
    // Fire-and-forget - don't await
    pruningService.pruneOldEntries().ignore();
  } catch (e) {
    // Silent fail - pruning is best-effort
    debugPrint('Cache pruning skipped: $e');
  }
}
