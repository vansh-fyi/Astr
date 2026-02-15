import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_toast.dart';
import '../../../context/domain/entities/astr_context.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../../dashboard/presentation/widgets/nebula_background.dart';
import '../../domain/entities/user_location.dart';
import '../providers/user_locations_provider.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UserLocation>> savedLocationsAsync = ref.watch(userLocationsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      body: Stack(
        children: <Widget>[
          const NebulaBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
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
                    data: (List<UserLocation> locations) {
                      if (locations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
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
                            colors: <Color>[Colors.transparent, Colors.white],
                            stops: <double>[0, 0.05],
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
                          itemBuilder: (BuildContext context, int index) {
                            final UserLocation location = locations[index];
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
                              confirmDismiss: (DismissDirection direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext dialogContext) => AlertDialog(
                                    backgroundColor: const Color(0xFF141419),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text(
                                      'Delete Location?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete "${location.name}"? This action cannot be undone.',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (DismissDirection direction) {
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
                    error: (Object err, StackTrace stack) => Center(
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

  const _LocationItem({required this.location});
  final UserLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isStale = UserLocationsNotifier.isStale(location);
    
    return GlassPanel(
      onTap: () {
        final GeoLocation geoLocation = GeoLocation(
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
        children: <Widget>[
          // Icon with pin indicator
          Stack(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Ionicons.location,
                    size: 24,
                    color: isStale ? Colors.white.withOpacity(0.5) : Colors.white,
                  ),
                ),
              ),
              // Pin badge (top-right corner of icon)
              if (location.isPinned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Ionicons.pin,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Name, Coords, and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isStale ? Colors.white.withOpacity(0.6) : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Stale badge
                    if (isStale)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.withOpacity(0.6), width: 1),
                        ),
                        child: const Text(
                          'Stale',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)} • ${_formatLastViewed(location.lastViewedTimestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(isStale ? 0.3 : 0.5),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          // Pin toggle button
          IconButton(
            icon: Icon(
              location.isPinned ? Ionicons.pin : Ionicons.pin_outline,
              color: location.isPinned ? Colors.amber : Colors.white.withOpacity(0.4),
              size: 20,
            ),
            onPressed: () async {
              try {
                final notifier = ref.read(userLocationsNotifierProvider.notifier);
                final newState = await notifier.togglePinned(location.id);
                if (context.mounted) {
                  showGlassToast(
                    context,
                    newState ? 'Location pinned' : 'Location unpinned',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showGlassToast(context, 'Failed to update pin status');
                }
              }
            },
            tooltip: location.isPinned ? 'Unpin location' : 'Pin location',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          
          const SizedBox(width: 4),
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
  
  /// Formats lastViewedTimestamp in human-readable relative format.
  String _formatLastViewed(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  void _showLocationOptions(BuildContext context, WidgetRef ref, UserLocation location) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Ensure it shows above bottom nav
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 50.0 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
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
                children: <Widget>[
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
              onTap: () async {
                context.pop(); // Close sheet
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF141419),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Delete Location?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Are you sure you want to delete "${location.name}"? This action cannot be undone.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  _deleteLocation(context, ref, location);
                }
              },
              padding: const EdgeInsets.all(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              child: Row(
                children: <Widget>[
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

void _deleteLocation(BuildContext context, WidgetRef ref, UserLocation location) {
  final AstrContext? currentContext = ref.read(astrContextProvider).value;
  final bool isCurrent = currentContext?.location.latitude == location.latitude &&
      currentContext?.location.longitude == location.longitude;

  ref.read(userLocationsNotifierProvider.notifier).deleteLocation(location.id);

  if (isCurrent) {
    ref.read(astrContextProvider.notifier).refreshLocation();
    showGlassToast(context, '${location.name} deleted. Reset to current location.');
  } else {
    showGlassToast(context, '${location.name} deleted');
  }
}
