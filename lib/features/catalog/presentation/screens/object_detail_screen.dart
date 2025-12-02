import 'package:astr/core/widgets/glass_panel.dart';
import 'package:astr/features/dashboard/presentation/widgets/nebula_background.dart';
import 'package:astr/features/catalog/domain/entities/celestial_type.dart';
import 'package:astr/features/catalog/presentation/providers/object_detail_notifier.dart';
import 'package:astr/features/catalog/presentation/providers/rise_set_provider.dart';
import 'package:astr/features/catalog/presentation/widgets/visibility_graph_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Full-featured object detail page (AC: 1-6)
class ObjectDetailScreen extends ConsumerWidget {
  final String objectId;

  const ObjectDetailScreen({
    super.key,
    required this.objectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(objectDetailNotifierProvider(objectId));

    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      extendBody: true,
      body: Stack(
        children: [
          const NebulaBackground(),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Header (like HomeScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : state.error != null
                          ? Center(
                              child: Text(
                                state.error!,
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            )
                          : state.object == null
                              ? const Center(
                                  child: Text(
                                    'Object not found',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                )
                              : ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.white],
                                      stops: [0.0, 0.05],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 20,
                                      bottom: 70 + MediaQuery.of(context).padding.bottom + 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // AC #3: Object Header
                                        _buildHeader(state.object!),
                                        const SizedBox(height: 32),

                                        // AC #4, #5: Basic Data Display with Glass Styling
                                        _buildDataSection(state, ref),
                                        const SizedBox(height: 32),

                                        // Story 3.3: Visibility Graph
                                        VisibilityGraphWidget(objectId: objectId),
                                      ],
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

  /// AC #3: Large title, type badge, hero icon
  Widget _buildHeader(object) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Icon
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForType(object.type),
              size: 64,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Large Title
        Text(
          object.name,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            object.type.displayName.substring(
              0,
              object.type.displayName.length - 1,
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// AC #4, #5: Data cards with GlassPanel
  Widget _buildDataSection(ObjectDetailState state, WidgetRef ref) {
    final object = state.object!;
    
    // Use riseSetProvider for consistent data with cards
    final riseSetAsync = ref.watch(riseSetProvider(object));
    
    final times = riseSetAsync.valueOrNull ?? {'rise': null, 'set': null};
    final riseTime = times['rise'];
    final setTime = times['set'];

    final rise = riseTime != null ? DateFormat('HH:mm').format(riseTime) : '-- : --';
    final set = setTime != null ? DateFormat('HH:mm').format(setTime) : '-- : --';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Magnitude
        if (object.magnitude != null)
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Magnitude',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  object.magnitude!.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Distance
        GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distance',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                object.type == CelestialType.planet ? 'Variable' : 'N/A',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rise/Set Times
        GlassPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rise/Set Times',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '↑ $rise | ↓ $set',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(CelestialType type) {
    switch (type) {
      case CelestialType.planet:
        return Icons.public;
      case CelestialType.star:
        return Icons.star;
      case CelestialType.constellation:
        return Icons.grid_on;
      case CelestialType.galaxy:
        return Icons.blur_circular;
      case CelestialType.nebula:
        return Icons.cloud;
      case CelestialType.cluster:
        return Icons.grain;
    }
  }
}