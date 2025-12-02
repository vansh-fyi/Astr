import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/core/widgets/glass_toast.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/dashboard/presentation/widgets/nebula_background.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/profile/presentation/providers/saved_locations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocationsAsync = ref.watch(savedLocationsNotifierProvider);

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
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Locations',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: savedLocationsAsync.when(
                    data: (locations) {
                      if (locations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Ionicons.location_outline,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saved locations',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white],
                            stops: [0.0, 0.05],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView.separated(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom: 70 + MediaQuery.of(context).padding.bottom + 20,
                          ),
                          itemCount: locations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            return Dismissible(
                              key: Key(location.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Ionicons.trash, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                _deleteLocation(context, ref, location);
                              },
                              child: _LocationItem(location: location),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120), // Lift clearly above nav bar
        child: FloatingActionButton(
          onPressed: () {
            context.push('/settings/locations/add');
          },
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _LocationItem extends ConsumerWidget {
  final SavedLocation location;

  const _LocationItem({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassPanel(
      onTap: () {
        final geoLocation = GeoLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          name: location.name,
        );
        ref.read(astrContextProvider.notifier).updateLocation(geoLocation);
        context.go('/'); // Go home after selecting
      },
      onLongPress: () => _showLocationOptions(context, ref, location),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Ionicons.location,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name and Coords
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  location.placeName ?? '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: location.placeName != null ? null : 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Zone Badge (Bortle)
          if (location.bortleClass != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Zone ${location.bortleClass}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          // Arrow
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showLocationOptions(BuildContext context, WidgetRef ref, SavedLocation location) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Ensure it shows above bottom nav
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 24.0,
          bottom: 50.0 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              location.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              location.placeName ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Edit Option
            GlassPanel(
              onTap: () {
                context.pop(); // Close sheet
                context.push('/settings/locations/add', extra: location);
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Ionicons.create, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Edit Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Delete Option
            GlassPanel(
              onTap: () {
                context.pop(); // Close sheet
                _deleteLocation(context, ref, location);
              },
              padding: const EdgeInsets.all(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Ionicons.trash, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Delete Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

void _deleteLocation(BuildContext context, WidgetRef ref, SavedLocation location) {
  final currentContext = ref.read(astrContextProvider).value;
  final isCurrent = currentContext?.location.latitude == location.latitude &&
      currentContext?.location.longitude == location.longitude;

  ref.read(savedLocationsNotifierProvider.notifier).deleteLocation(location.id);

  if (isCurrent) {
    ref.read(astrContextProvider.notifier).refreshLocation();
    showGlassToast(context, '${location.name} deleted. Reset to current location.');
  } else {
    showGlassToast(context, '${location.name} deleted');
  }
}
