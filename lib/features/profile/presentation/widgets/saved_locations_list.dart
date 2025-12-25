import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_toast.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../context/presentation/providers/astr_context_provider.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/saved_locations_provider.dart';

class SavedLocationsList extends ConsumerWidget {
  const SavedLocationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SavedLocation>> savedLocationsAsync = ref.watch(savedLocationsNotifierProvider);

    return savedLocationsAsync.when(
      data: (List<SavedLocation> locations) {
        if (locations.isEmpty) {
          return const ListTile(
            title: Text('No saved locations'),
            leading: Icon(Icons.location_off),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Saved Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...locations.map((SavedLocation location) => _SavedLocationTile(location: location)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object err, StackTrace stack) => ListTile(
        title: Text('Error loading locations: $err'),
        leading: const Icon(Icons.error),
      ),
    );
  }
}

class _SavedLocationTile extends ConsumerWidget {

  const _SavedLocationTile({required this.location});
  final SavedLocation location;

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
        padding: const EdgeInsets.only(right: 20),
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
          final GeoLocation geoLocation = GeoLocation(
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
