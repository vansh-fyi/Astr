import 'dart:ui';
import 'package:astr/core/widgets/glass_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/context/presentation/widgets/location_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'package:astr/core/providers/global_loading_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final astrContextAsync = ref.watch(astrContextProvider);
    final selectedDate = astrContextAsync.value?.selectedDate ?? DateTime.now();
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    
    final locationName = astrContextAsync.value?.isCurrentLocation == true 
        ? 'Current Location' 
        : (astrContextAsync.value?.location.name ?? 'Current Location');

    final topPadding = MediaQuery.of(context).padding.top;
    final isLoading = ref.watch(globalLoadingProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Page Content (Pushed down to be visible below header)
          Padding(
            padding: const EdgeInsets.only(top: 55), 
            child: navigationShell,
          ),
          
          // Global Glass Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    top: topPadding + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.deepCosmos.withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Group
                      Flexible(
                        flex: 4, // Increased flex to ensure "Current Location" fits
                        child: GlassPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              builder: (context) => const LocationSheet(),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Ionicons.location_outline, 
                                color: (astrContextAsync.value?.isCurrentLocation ?? true) 
                                    ? Colors.white 
                                    : Colors.blueAccent,
                                size: 14
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  locationName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (astrContextAsync.value?.isCurrentLocation ?? true)
                                        ? Colors.white.withOpacity(0.9)
                                        : Colors.blueAccent,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Date Group
                      Flexible(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Prev Button
                            GlassPanel(
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                ref.read(astrContextProvider.notifier).updateDate(
                                  selectedDate.subtract(const Duration(days: 1)),
                                );
                              },
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Ionicons.chevron_back, color: Colors.white70, size: 16),
                              ),
                            ),
                            
                            const SizedBox(width: 6),

                            // Date Pill
                            Flexible(
                              child: GlassPanel(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                borderRadius: BorderRadius.circular(30),
                                onTap: () async {
                                  final now = DateTime.now();
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: now.subtract(const Duration(days: 365)),
                                    lastDate: now.add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Colors.blueAccent,
                                            onPrimary: Colors.white,
                                            surface: const Color(0xFF141419),
                                            onSurface: Colors.white,
                                          ),
                                          dialogBackgroundColor: const Color(0xFF0A0A0B),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (pickedDate != null) {
                                    ref.read(astrContextProvider.notifier).updateDate(pickedDate);
                                  }
                                },
                                child: Text(
                                  DateFormat('MMM d').format(selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isToday ? Colors.white.withOpacity(0.9) : Colors.blueAccent,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Next Button
                            GlassPanel(
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                ref.read(astrContextProvider.notifier).updateDate(
                                  selectedDate.add(const Duration(days: 1)),
                                );
                              },
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Ionicons.chevron_forward, color: Colors.white70, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading Overlay
          _buildLoadingOverlay(isLoading),
        ],
      ),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showGlassToast(context, 'Sky Map coming soon!');
        },
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Ionicons.map_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: NavBarClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppTheme.glassBlur,
                sigmaY: AppTheme.glassBlur,
              ),
              child: Container(
                height: 70 + bottomPadding,
                color: AppTheme.deepCosmos.withOpacity(0.8),
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavBarItem(
                        icon: Ionicons.home_outline,
                        activeIcon: Ionicons.home,
                        label: 'Home',
                        isSelected: navigationShell.currentIndex == 0,
                        onTap: () => _onTap(context, 0),
                      ),
                      _NavBarItem(
                        icon: Ionicons.planet_outline,
                        activeIcon: Ionicons.planet,
                        label: 'Objects',
                        isSelected: navigationShell.currentIndex == 1,
                        onTap: () => _onTap(context, 1),
                      ),
                      const SizedBox(width: 48), // Spacer for FAB
                      _NavBarItem(
                        icon: Ionicons.calendar_outline,
                        activeIcon: Ionicons.calendar,
                        label: 'Forecast',
                        isSelected: navigationShell.currentIndex == 2,
                        onTap: () => _onTap(context, 2),
                      ),
                      _NavBarItem(
                        icon: Ionicons.settings_outline,
                        activeIcon: Ionicons.settings,
                        label: 'Settings',
                        isSelected: navigationShell.currentIndex == 3,
                        onTap: () => _onTap(context, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Shine Effect
          IgnorePointer(
            child: CustomPaint(
              size: const Size(100, 40), // Approximate size of the notch area
              painter: NotchShinePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isLoading) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141419),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final center = size.width / 2;
    
    // Start from top-left
    path.moveTo(0, 0);
    
    // Line to the start of the notch
    path.lineTo(center - 50, 0);
    
    // The Notch Curve (Same as NotchShinePainter)
    path.cubicTo(
      center - 35, 0,      // Control point 1
      center - 35, 42,     // Control point 2
      center, 42           // End point (bottom center)
    );
    path.cubicTo(
      center + 35, 42,     // Control point 1
      center + 35, 0,      // Control point 2
      center + 50, 0       // End point
    );
    
    // Line to top-right
    path.lineTo(size.width, 0);
    
    // Line to bottom-right
    path.lineTo(size.width, size.height);
    
    // Line to bottom-left
    path.lineTo(0, size.height);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class NotchShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Gradient to create the "shine" effect
    // Fades out at the ends (top) and bottom, concentrating the shine in the middle
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.blueAccent.withOpacity(0.0),
        Colors.blueAccent.withOpacity(0.8),
        Colors.blueAccent.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = shader;

    final path = Path();
    final center = size.width / 2;
    
    // We draw a curve that follows the notch shape.
    // Starting from the top edge (y=0) and curving down.
    
    // Left side of the notch
    path.moveTo(center - 50, 0); 
    path.cubicTo(
      center - 35, 0,      // Control point 1 (flat start)
      center - 35, 42,     // Control point 2 (curve down)
      center, 42           // End point (bottom center of notch)
    );
    
    // Right side of the notch
    path.cubicTo(
      center + 35, 42,     // Control point 1 (curve up)
      center + 35, 0,      // Control point 2 (flat end)
      center + 50, 0       // End point
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.5);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
