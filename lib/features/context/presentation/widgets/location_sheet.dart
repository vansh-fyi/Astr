import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/core/widgets/glass_toast.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/profile/presentation/providers/saved_locations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:uuid/uuid.dart';

class LocationSheet extends ConsumerStatefulWidget {
  const LocationSheet({super.key});

  @override
  ConsumerState<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<LocationSheet> {
  bool _isLoadingGPS = false;

  @override
  Widget build(BuildContext context) {
    final astrContextAsync = ref.watch(astrContextProvider);
    final savedLocationsAsync = ref.watch(savedLocationsNotifierProvider);
    
    final currentContext = astrContextAsync.value;
    final isCurrentLocationActive = currentContext?.isCurrentLocation ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 24.0,
          bottom: 50.0 + MediaQuery.of(context).padding.bottom,
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
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 1. Current Location (GPS) Option
            GlassPanel(
              onTap: () async {
                if (isCurrentLocationActive) {
                  Navigator.pop(context);
                  return;
                }

                setState(() => _isLoadingGPS = true);
                try {
                  await ref.read(astrContextProvider.notifier).refreshLocation();
                  if (mounted) Navigator.pop(context);
                } finally {
                  if (mounted) setState(() => _isLoadingGPS = false);
                }
              },
              padding: const EdgeInsets.all(16),
              border: isCurrentLocationActive 
                  ? Border.all(color: Colors.blueAccent, width: 1)
                  : null,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoadingGPS 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
                          )
                        : const Icon(Ionicons.navigate, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // We don't show specific coords here unless active, or maybe just "GPS"
                        Text(
                          isCurrentLocationActive 
                              ? (currentContext?.location.placeName ?? 'Unknown')
                              : 'Use device location',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentLocationActive)
                    const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Saved Locations List
            savedLocationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  children: locations.map((loc) {
                    final isActive = !isCurrentLocationActive && 
                        currentContext?.location.latitude == loc.latitude &&
                        currentContext?.location.longitude == loc.longitude;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPanel(
                        onTap: () {
                          if (isActive) {
                            Navigator.pop(context);
                            return;
                          }
                          
                          final geoLocation = GeoLocation(
                            latitude: loc.latitude,
                            longitude: loc.longitude,
                            name: loc.name,
                            placeName: loc.placeName,
                          );
                          
                          ref.read(astrContextProvider.notifier).updateLocation(geoLocation);
                          Navigator.pop(context);
                        },
                        onLongPress: () => _showLocationOptions(context, ref, loc),
                        padding: const EdgeInsets.all(16),
                        border: isActive 
                            ? Border.all(color: Colors.blueAccent, width: 1) 
                            : null,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Ionicons.location, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.placeName ?? '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 3. Add Location Manually Button
            GlassPanel(
              onTap: () {
                Navigator.pop(context); // Close sheet
                context.push('/settings/locations/add'); // Navigate to add screen
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Ionicons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Add Location Manually',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                // We need to close the LocationSheet as well if we want to go to edit screen cleanly
                // But context.pop() only closes the options sheet.
                // If we push, it goes on top.
                // Let's just push.
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
                context.pop(); // Close options sheet
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

  void _deleteLocation(BuildContext context, WidgetRef ref, SavedLocation location) {
    // We are in LocationSheet.
    // If we delete, we should probably close the sheet or refresh it.
    // The provider watcher will refresh the list automatically.
    
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
}
