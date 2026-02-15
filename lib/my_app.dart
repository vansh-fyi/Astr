import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/widgets/red_mode_overlay.dart';
import 'features/dashboard/data/models/weather_cache_entry.dart';
import 'features/dashboard/data/services/weather_cache_pruning_service.dart';
import 'features/profile/presentation/providers/settings_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late WeatherCachePruningService? _pruningService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize pruning service
    try {
      final Box<WeatherCacheEntry> cacheBox = Hive.box<WeatherCacheEntry>('weatherCache');
      _pruningService = WeatherCachePruningService(cacheBox: cacheBox);
    } catch (e) {
      debugPrint('Failed to initialize pruning service: $e');
      _pruningService = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // FR-10: Prune old cache when app returns from background
    if (state == AppLifecycleState.resumed) {
      _pruningService?.pruneOldEntries().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(goRouterProvider);
    final bool redMode = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Astr',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force Dark Mode for "Deep Cosmos"
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (BuildContext context, Widget? child) {
        return RedModeOverlay(
          enabled: redMode,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
}
