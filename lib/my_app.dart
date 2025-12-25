import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/widgets/red_mode_overlay.dart';
import 'features/profile/presentation/providers/settings_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
