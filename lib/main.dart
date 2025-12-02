// ignore_for_file: always_put_control_body_on_new_line

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

import 'constants/strings.dart';
import 'features/astronomy/data/repositories/astro_engine_impl.dart';
import 'features/astronomy/domain/services/astronomy_service.dart';
import 'hive/hive.dart';
import 'my_app.dart';

/// Try using const constructors as much as possible!

void main() async {
  /// Initialize packages
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initHive();
  // await AstroEngineImpl.initialize(); // Disabled for visual testing
  await setPreferredOrientations();
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  }

  // Initialize Astronomy Service (Swiss Ephemeris)
  final container = ProviderContainer();
  try {
    await container.read(astronomyServiceProvider).init();
  } catch (e) {
    debugPrint('Failed to initialize AstronomyService: $e');
  }

  if (kReleaseMode) {
    /// Disable debugPrint in release mode
    /// This will prevent any debugPrint statements from being executed
    /// and will not print anything to the console.
    /// You can also use a custom implementation if needed
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  runApp(
    UncontrolledProviderScope(
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
  );

  /// Add this line to get the error stack trace in release mode
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
}
