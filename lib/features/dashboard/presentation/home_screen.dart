import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/engine/models/condition_result.dart';
import '../../../core/engine/models/sky_state.dart';
import '../../../core/services/toast_service.dart';
import '../../astronomy/domain/entities/astronomy_state.dart';
import '../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../context/domain/entities/astr_context.dart';
import '../../context/domain/entities/geo_location.dart';
import '../../context/presentation/providers/astr_context_provider.dart';
import '../../splash/domain/entities/launch_result.dart';
import '../../splash/presentation/providers/smart_launch_provider.dart';
import '../domain/entities/weather.dart';
import 'providers/condition_quality_provider.dart';
import 'providers/visibility_provider.dart';
import 'providers/weather_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/hero_condition_label.dart';
import 'widgets/highlights_feed.dart';
import 'widgets/sky_state_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bannerController;
  Timer? _bannerTimer;
  DateTime? _lastSelectedDate;
  bool _isFutureDate = false;
  bool _hasHandledLaunchToast = false;
  bool _hasHandledLaunchLocation = false;

  @override
  void initState() {
    super.initState();

    // Story 4.2: Set status bar style for OLED black background (NFR-09)
    // Set once in initState to avoid repeated calls on every rebuild
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.light, // White icons (Android)
        statusBarBrightness: Brightness.dark, // Dark content = light icons (iOS)
        systemNavigationBarColor: Color(0xFF000000), // Pure black nav bar
        systemNavigationBarIconBrightness: Brightness.light, // White nav icons
      ),
    );

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _handleDateChange(DateTime newDate) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime selected = DateUtils.dateOnly(newDate);

    if (selected == today) {
      // Today — hide banner
      _bannerTimer?.cancel();
      _bannerController.reverse();
    } else if (!DateUtils.isSameDay(newDate, _lastSelectedDate)) {
      // Different non-today date — show banner then auto-hide
      setState(() {
        _isFutureDate = selected.isAfter(today);
      });
      _bannerTimer?.cancel();
      _bannerController.forward();

      _bannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _bannerController.reverse();
        }
      });
    }
    _lastSelectedDate = newDate;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Weather> weatherAsync = ref.watch(weatherProvider);
    final AsyncValue<AstronomyState> astronomyAsync = ref.watch(astronomyProvider);
    final VisibilityState visibilityState = ref.watch(visibilityProvider);
    final AsyncValue<AstrContext> astrContextAsync = ref.watch(astrContextProvider);

    final DateTime selectedDate = astrContextAsync.value?.selectedDate ?? DateTime.now();

    // Story 4.1: Handle smart launch result (Zero-Click UX)
    // Use watch instead of listen to safely handle initial state (fixes race condition)
    final AsyncValue<LaunchResult> launchAsync = ref.watch(launchResultProvider);
    
    // Perform state updates based on launch result (only once if needed)
    // We use a post-frame callback to avoid build-phase state modification error
    if (launchAsync.hasValue) {
      final LaunchResult result = launchAsync.value!;
     
      switch (result) {
        case LaunchSuccess(:final location):
          // Pre-loaded location from launch controller — run ONCE only.
          // Without the guard, every rebuild re-checks the launch location
          // against the current context. When the user picks a saved location,
          // the mismatch triggers updateLocation(gpsLocation), reverting
          // the selection back to GPS.
          if (!_hasHandledLaunchLocation) {
            _hasHandledLaunchLocation = true;
            final GeoLocation? currentLocation = astrContextAsync.value?.location;
            if (currentLocation == null ||
                currentLocation.latitude != location.latitude ||
                currentLocation.longitude != location.longitude) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 ref.read(astrContextProvider.notifier).updateLocation(location);
               });
            }
          }
          break;

        case LaunchTimeout():
          // NFR-10: GPS timeout → Show toast and continue with default/cached location
          if (!_hasHandledLaunchToast) {
            _hasHandledLaunchToast = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ToastService.showGPSTimeout(context);
              }
            });
          }
          break;

        case LaunchPermissionDenied():
          // Permission denied → Show toast explaining manual entry is needed
          if (!_hasHandledLaunchToast) {
            _hasHandledLaunchToast = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ToastService.showError(
                  context,
                  'Location permission denied. Tap location icon to set manually.',
                );
              }
            });
          }
          break;

        case LaunchServiceDisabled():
          // Location service disabled → Show toast
          if (!_hasHandledLaunchToast) {
            _hasHandledLaunchToast = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ToastService.showInfo(
                  context,
                  'Location services disabled. Tap location icon to set manually.',
                );
              }
            });
          }
          break;
      }
    }

    // Listen for date changes only to trigger banner animation
    ref.listen(astrContextProvider, (AsyncValue<AstrContext>? previous, AsyncValue<AstrContext> next) {
      final DateTime? newDate = next.value?.selectedDate;
      final DateTime? oldDate = previous?.value?.selectedDate;
      if (newDate != null && !DateUtils.isSameDay(newDate, oldDate)) {
        _handleDateChange(newDate);
      }
    });

    final AsyncValue<ConditionResult> conditionAsync = ref.watch(conditionQualityProvider);
    final SkyState skyState = conditionAsync.when(
      data: (ConditionResult result) => result.skyState,
      loading: () => SkyState.starrySkies,
      error: (_, __) => SkyState.starrySkies,
    );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF000000), // Pure black for OLED (NFR-09)
      body: Stack(
        children: <Widget>[
          // z=0: Background
          SkyStateBackground(skyState: skyState),

          // z=1: Content
          SafeArea(
            bottom: false,
            child: Stack(
              children: <Widget>[
                // Scrollable content
                Positioned.fill(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait(<Future<void>>[
                        ref.read(astrContextProvider.notifier).refreshLocation(),
                        ref.read(weatherProvider.notifier).refresh(),
                      ]);
                    },
                    color: Colors.blueAccent,
                    backgroundColor: const Color(0xFF000000), // Pure black for OLED (NFR-09)
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: EdgeInsets.only(
                        top: AppSpacing.kHeaderContentOffset,
                        bottom: 70 + MediaQuery.of(context).padding.bottom + AppSpacing.md,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: <Widget>[
                            // Hero Section
                            HeroConditionLabel(
                              conditionResult: conditionAsync.valueOrNull,
                              astrZone: visibilityState.isLoading || visibilityState.lightPollution.visibilityIndex == 0
                                  ? null
                                  : visibilityState.lightPollution.visibilityIndex,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            
                            // Placeholder for ConditionsCard (Plan 03)
                            const SizedBox(height: AppSpacing.kConditionsCardHeight),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Placeholder for mini-cards (Plan 04)
                            const SizedBox(height: AppSpacing.kMiniCardHeight),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Highlights Feed
                            const HighlightsFeed(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Fixed Header and Banner on top
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const DashboardHeader(),
                    SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: _bannerController,
                        curve: Curves.easeOut,
                      ),
                      axisAlignment: -1.0,
                      child: Container(
                        width: double.infinity,
                        color: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Ionicons.time_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Viewing ${_isFutureDate ? "Future" : "Past"} Data: ${DateFormat('MMM d').format(selectedDate)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
