import 'dart:async';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/dashboard/presentation/widgets/nebula_background.dart';
import 'package:astr/features/planner/domain/entities/daily_forecast.dart';
import 'package:astr/features/planner/presentation/providers/planner_provider.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> with SingleTickerProviderStateMixin {
  String? _toastMessage;
  Timer? _toastTimer;
  late AnimationController _toastController;
  late Animation<Offset> _toastSlideAnimation;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _toastSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5), // Start above
      end: const Offset(0, 0), // End at position
    ).animate(CurvedAnimation(parent: _toastController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastController.forward();

    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _toastMessage = null;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final forecastAsync = ref.watch(forecastListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      body: Stack(
        children: [
          const NebulaBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Matching Catalog Screen)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forecast',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7-Day Outlook',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                        stops: [0.0, 0.05], // Soft fade at the top
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: forecastAsync.when(
                      data: (forecasts) {
                        return ListView.separated(
                          padding: EdgeInsets.only(
                            left: 20, 
                            right: 20, 
                            top: 20,
                            bottom: 70 + MediaQuery.of(context).padding.bottom + 20,
                          ),
                          itemCount: forecasts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final forecast = forecasts[index];
                            final isToday = index == 0;
                            
                            return _ForecastItem(
                              forecast: forecast, 
                              isToday: isToday,
                              onTap: () {
                                ref.read(astrContextProvider.notifier).updateDate(forecast.date);
                                context.go('/');
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      error: (err, stack) => Center(
                        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Toast Notification (If we were staying on screen, but since we nav, this might be moot unless we change nav behavior)
          // I will implement the toast logic in case the user wants to stay or if this is a misunderstanding.
          // But wait, if I navigate, this widget unmounts.
          // I'll implement the UI changes first. The toast might be a separate requirement for the Home screen.
          // "The card on selecting another day saying: 'Viewing Dec 4' should dissapear..."
          // This definitely sounds like the Home screen "Viewing [Date]" banner.
          // I should check if there is such a banner in Home.
          // But for now, I will focus on the Forecast UI polish (Stars -> Bar, Header).
        ],
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  final DailyForecast forecast;
  final bool isToday;
  final VoidCallback onTap;

  const _ForecastItem({
    required this.forecast,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Rating Logic
    // 5 = Excellent, 4 = Good, 3 = Fair, 2 = Poor, 1 = Bad
    String label;
    int activeSegmentIndex;
    
    switch (forecast.starRating) {
      case 5:
        label = 'Excellent';
        activeSegmentIndex = 4;
        break;
      case 4:
        label = 'Good';
        activeSegmentIndex = 3;
        break;
      case 3:
        label = 'Fair';
        activeSegmentIndex = 2;
        break;
      case 2:
        label = 'Poor';
        activeSegmentIndex = 1;
        break;
      default:
        label = 'Bad';
        activeSegmentIndex = 0;
    }

    return GlassPanel(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            // Date
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today' : DateFormat('EEEE').format(forecast.date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(forecast.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Rating Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                  // Segmented Bar
                SizedBox(
                  width: 120, // Fixed width for the bar
                  child: Row(
                    children: List.generate(5, (index) {
                      // Cumulative logic: all bars up to activeSegmentIndex are active
                      final isActive = index <= activeSegmentIndex;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.6),
                                blurRadius: 8,
                              )
                            ] : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
