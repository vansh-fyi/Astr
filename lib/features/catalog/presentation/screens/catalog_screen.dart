import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/cosmic_loader.dart';
import '../../../dashboard/presentation/widgets/nebula_background.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/celestial_type.dart';
import '../providers/catalog_notifier.dart';
import '../widgets/object_list_item.dart';

/// Main catalog screen showing list of celestial objects
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CatalogState state = ref.watch(catalogNotifierProvider);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Celestial Objects',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explore the cosmos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filter (ChoiceChip style)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: CelestialType.values.map((CelestialType type) {
                      final bool isSelected = state.selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(catalogNotifierProvider.notifier).switchCategory(type);
                          },
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedColor: Colors.blue.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Object List
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
                    child: state.isLoading
                        ? const Center(child: CosmicLoader())
                        : state.error != null
                            ? Center(
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : state.objects.isEmpty
                                ? Center(
                                    child: Text(
                                      'No objects found',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 20,
                                      bottom: 70 + MediaQuery.of(context).padding.bottom + 20,
                                    ),
                                    itemCount: state.objects.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (BuildContext context, int index) {
                                      final CelestialObject object = state.objects[index];
                                      return ObjectListItem(
                                        object: object,
                                        onTap: () {
                                          // Navigate to detail page (placeholder for Story 3.2)
                                          context.push('/catalog/${object.id}');
                                        },
                                      );
                                    },
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
