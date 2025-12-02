import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/context/presentation/providers/astr_context_provider.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'package:astr/features/profile/presentation/providers/saved_locations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/core/widgets/glass_toast.dart';

class SavedLocationsList extends ConsumerWidget {
  const SavedLocationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocationsAsync = ref.watch(savedLocationsNotifierProvider);

    return savedLocationsAsync.when(
      data: (locations) {
        if (locations.isEmpty) {
          return const ListTile(
            title: Text('No saved locations'),
            leading: Icon(Icons.location_off),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Saved Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...locations.map((location) => _SavedLocationTile(location: location)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ListTile(
        title: Text('Error loading locations: $err'),
        leading: const Icon(Icons.error),
      ),
    );
  }
}

class _SavedLocationTile extends ConsumerWidget {
  final SavedLocation location;

  const _SavedLocationTile({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(location.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(savedLocationsNotifierProvider.notifier).deleteLocation(location.id);
        showGlassToast(context, '${location.name} deleted');
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on),
        title: Text(location.name),
        subtitle: Text(
          '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'
          '${location.bortleClass != null ? ' • Bortle ${location.bortleClass}' : ''}',
        ),
        onTap: () {
          final geoLocation = GeoLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            name: location.name,
          );
          ref.read(astrContextProvider.notifier).updateLocation(geoLocation);
          context.go('/');
        },
      ),
    );
  }
}
