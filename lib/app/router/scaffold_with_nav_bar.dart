import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_typography.dart';
import '../../core/providers/global_loading_provider.dart';
import '../../core/widgets/cosmic_loader.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/glass_toast.dart';
import '../../features/context/domain/entities/astr_context.dart';
import '../../features/context/presentation/providers/astr_context_provider.dart';
import '../../features/context/presentation/widgets/location_sheet.dart';

class ScaffoldWithNavBar extends ConsumerWidget {

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final AsyncValue<AstrContext> astrContextAsync = ref.watch(astrContextProvider);
    final DateTime selectedDate = astrContextAsync.value?.selectedDate ?? DateTime.now();
    final bool isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    
    final String locationName = astrContextAsync.value?.isCurrentLocation ?? false 
        ? 'Current Location' 
        : (astrContextAsync.value?.location.name ?? 'Current Location');

    final bool isLoading = ref.watch(globalLoadingProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          // Page Content (Pushed down to be visible below header)
          Padding(
            padding: const EdgeInsets.only(top: 55), 
            child: navigationShell,
          ),
          
          // Global Header — transparent, logo centered
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Center: Astr logo
                    Image.asset(
                      'assets/icons/astr/logo.png',
                      width: 28,
                      height: 28,
                    ),

                    // Left: Location pill
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: BorderRadius.circular(30),
                        backgroundColor: AppColors.surfaceGlass,
                        borderColor: AppColors.borderSurface,
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            useRootNavigator: true,
                            builder: (BuildContext context) => const LocationSheet(),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Ionicons.location_outline,
                              color: (astrContextAsync.value?.isCurrentLocation ?? true)
                                  ? AppColors.textPrimary
                                  : AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                locationName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: (astrContextAsync.value?.isCurrentLocation ?? true)
                                      ? AppColors.textPrimary
                                      : AppColors.accent,
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

                    // Right: Date navigation
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Prev button
                          GlassPanel(
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(30),
                            backgroundColor: AppColors.surfaceGlass,
                            borderColor: AppColors.borderSurface,
                            onTap: () {
                              final DateTime now = DateTime.now();
                              final DateTime minDate = now.subtract(const Duration(days: 10));
                              final DateTime nextDate = selectedDate.subtract(const Duration(days: 1));
                              if (nextDate.isBefore(minDate)) {
                                showGlassToast(context, 'Cloud cover forecast unavailable beyond 10 days in the past');
                                return;
                              }
                              ref.read(astrContextProvider.notifier).updateDate(nextDate);
                            },
                            child: const SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(Ionicons.chevron_back, color: AppColors.textMuted, size: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Date pill
                          GlassPanel(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            borderRadius: BorderRadius.circular(30),
                            backgroundColor: AppColors.surfaceGlass,
                            borderColor: AppColors.borderSurface,
                            onTap: () async {
                              final DateTime now = DateTime.now();
                              final DateTime minDate = now.subtract(const Duration(days: 10));
                              final DateTime maxDate = now.add(const Duration(days: 10));
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: minDate,
                                lastDate: maxDate,
                                helpText: 'Cloud cover forecast available for ±10 days',
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.accent,
                                        onPrimary: AppColors.textPrimary,
                                        surface: Color(0xFF141419),
                                      ),
                                      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0A0A0B)),
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
                                color: isToday ? AppColors.textPrimary : AppColors.accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Next button
                          GlassPanel(
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(30),
                            backgroundColor: AppColors.surfaceGlass,
                            borderColor: AppColors.borderSurface,
                            onTap: () {
                              final DateTime now = DateTime.now();
                              final DateTime maxDate = now.add(const Duration(days: 10));
                              final DateTime nextDate = selectedDate.add(const Duration(days: 1));
                              if (nextDate.isAfter(maxDate)) {
                                showGlassToast(context, 'Cloud cover forecast unavailable beyond 10 days in the future');
                                return;
                              }
                              ref.read(astrContextProvider.notifier).updateDate(nextDate);
                            },
                            child: const SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(Ionicons.chevron_forward, color: AppColors.textMuted, size: 14),
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
          // Loading Overlay
          _buildLoadingOverlay(isLoading),
        ],
      ),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showGlassToast(context, 'Sky Map coming soon!');
        },
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: const Icon(Ionicons.map_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          ClipPath(
            clipper: NavBarClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 16,
                sigmaY: 16,
              ),
              child: Container(
                height: 70 + bottomPadding,
                color: AppColors.surfaceGlass,
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: <Widget>[
                      const SizedBox(width: 32),
                      _NavBarItem(
                        icon: Ionicons.home_outline,
                        activeIcon: Ionicons.home,
                        label: 'Home',
                        isSelected: navigationShell.currentIndex == 0,
                        onTap: () => _onTap(context, 0),
                      ),
                      const SizedBox(width: 20),
                      _NavBarItem(
                        icon: Ionicons.planet_outline,
                        activeIcon: Ionicons.planet,
                        label: 'Objects',
                        isSelected: navigationShell.currentIndex == 1,
                        onTap: () => _onTap(context, 1),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // FAB notch gap
                      const Spacer(),
                      _NavBarItem(
                        icon: Ionicons.calendar_outline,
                        activeIcon: Ionicons.calendar,
                        label: 'Forecast',
                        isSelected: navigationShell.currentIndex == 2,
                        onTap: () => _onTap(context, 2),
                      ),
                      const SizedBox(width: 20),
                      _NavBarItem(
                        icon: Ionicons.settings_outline,
                        activeIcon: Ionicons.settings,
                        label: 'Settings',
                        isSelected: navigationShell.currentIndex == 3,
                        onTap: () => _onTap(context, 3),
                      ),
                      const SizedBox(width: 32),
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
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.5),
        child: const Center(
          child: CosmicLoader(),
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
    final Path path = Path();
    final double center = size.width / 2;
    
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
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Gradient to create the "shine" effect
    // Fades out at the ends (top) and bottom, concentrating the shine in the middle
    final Shader shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        AppColors.accent.withValues(alpha: 0),
        AppColors.accent.withValues(alpha: 0.8),
        AppColors.accent.withValues(alpha: 0),
      ],
      stops: const <double>[0, 0.5, 1],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = shader;

    final Path path = Path();
    final double center = size.width / 2;
    
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

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected ? AppColors.textPrimary : AppColors.textSubdued;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isSelected ? activeIcon : icon,
              color: itemColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.nav.copyWith(
                color: itemColor,
                shadows: isSelected
                    ? const <Shadow>[
                        Shadow(
                          color: Color(0xFF3A7FFF),
                          blurRadius: 12.2,
                          offset: Offset(0, 1),
                        ),
                        Shadow(
                          color: Color(0x40FFFFFF),
                          blurRadius: 1,
                          offset: Offset.zero,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
