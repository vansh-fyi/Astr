import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/engine/models/condition_result.dart';
import '../../../core/widgets/cosmic_loader.dart';
import '../../astronomy/domain/entities/astronomy_state.dart';
import '../../astronomy/presentation/providers/astronomy_provider.dart';
import '../../context/domain/entities/astr_context.dart';
import '../../context/presentation/providers/astr_context_provider.dart';
import '../domain/entities/weather.dart';
import '../domain/services/quality_calculator.dart';
import 'providers/condition_quality_provider.dart';
import 'providers/visibility_provider.dart';
import 'providers/weather_provider.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/highlights_feed.dart';
import 'widgets/nebula_background.dart';
import 'widgets/sky_portal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlideAnimation;
  Timer? _bannerTimer;
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start slightly above (or 0 if using SizeTransition)
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AsyncValue<AstrContext> contextAsync = ref.read(astrContextProvider);
      final DateTime? selectedDate = contextAsync.value?.selectedDate;
      if (selectedDate != null && !DateUtils.isSameDay(selectedDate, DateTime.now())) {
        _handleDateChange(selectedDate);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _handleDateChange(DateTime newDate) {
    if (DateUtils.isSameDay(newDate, DateTime.now())) {
      // If today, hide immediately
      _bannerTimer?.cancel();
      _bannerController.reverse();
    } else {
      // If future date changed
      if (_lastSelectedDate == null || !DateUtils.isSameDay(newDate, _lastSelectedDate)) {
        _bannerTimer?.cancel();
        _bannerController.forward();
        
        _bannerTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _bannerController.reverse();
          }
        });
      }
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
    final bool isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    // Listen for changes to trigger animation
    ref.listen(astrContextProvider, (AsyncValue<AstrContext>? previous, AsyncValue<AstrContext> next) {
      final DateTime? newDate = next.value?.selectedDate;
      if (newDate != null) {
        _handleDateChange(newDate);
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF020204),
      body: Stack(
        children: <Widget>[
          // Background Elements
          const NebulaBackground(),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                // Header / Navigation removed (moved to global nav bar)
                // Future Date Banner
                SlideTransition(
                  position: _bannerSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    color: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Ionicons.time_outline, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Viewing Future Data: ${DateFormat('MMM d').format(selectedDate)}',
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
                ),
                
                const SizedBox(height: 16),

                // Scrollable Content
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, Colors.white],
                        stops: <double>[0, 0.05], // Soft fade at the top
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Refresh all data
                        await Future.wait(<Future<void>>[
                          ref.read(astrContextProvider.notifier).refreshLocation(),
                          ref.read(weatherProvider.notifier).refresh(),
                        ]);
                      },
                      color: Colors.blueAccent,
                      backgroundColor: const Color(0xFF141419),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: <Widget>[
                              const SizedBox(height: 20),
                              
                              const SizedBox(height: 20),
                              
                              // Sky Portal (Main Visual)
                              // Sky Portal (Hero)
                              if (weatherAsync.hasValue && astronomyAsync.hasValue) ...<Widget>[
                                Consumer(
                                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                    final Weather weather = weatherAsync.value!;
                                    final AstronomyState astronomy = astronomyAsync.value!;

                                    final int score = QualityCalculator.calculateScore(
                                      bortleScale: visibilityState.lightPollution.visibilityIndex.toDouble(),
                                      cloudCover: weather.cloudCover,
                                      moonIllumination: astronomy.moonPhaseInfo.illumination,
                                    );

                                    // Watch the qualitative condition provider
                                    final AsyncValue<ConditionResult> conditionAsync = ref.watch(conditionQualityProvider);

                                    return SkyPortal(
                                      qualityLabel: conditionAsync.valueOrNull?.shortSummary ?? 'Loading...',
                                      score: score,
                                      conditionResult: conditionAsync.valueOrNull,
                                      onTap: () {
                                        // TODO: Open Details Sheet
                                      },
                                    );
                                  },
                                ),
                              ] else ...<Widget>[
                                 const SizedBox(
                                   height: 300,
                                   child: CosmicLoader(),
                                 ),
                              ],

                              const SizedBox(height: 40),

                              // Dashboard Grid
                              if (weatherAsync.hasValue && astronomyAsync.hasValue) ...<Widget>[
                                 Builder(
                                  builder: (BuildContext context) {
                                    final Weather weather = weatherAsync.value!;
                                    final AstronomyState astronomy = astronomyAsync.value!;

                                    return DashboardGrid(
                                      cloudCover: weather.cloudCover,
                                      lightPollution: visibilityState.lightPollution,
                                      moonPhaseInfo: astronomy.moonPhaseInfo,
                                    );
                                  }
                                 ),
                              ],

                              const SizedBox(height: 24),

                              // Highlights Feed
                              const HighlightsFeed(),

                              SizedBox(
                                height: 70 + MediaQuery.of(context).padding.bottom + 20,
                              ), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
