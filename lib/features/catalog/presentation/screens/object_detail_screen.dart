import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/cosmic_loader.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../dashboard/presentation/widgets/nebula_background.dart';
import '../../domain/entities/celestial_object.dart';
import '../../domain/entities/celestial_type.dart';
import '../providers/object_detail_notifier.dart';
import '../providers/rise_set_provider.dart';
import '../widgets/visibility_graph_widget.dart';

/// Full-featured object detail page (AC: 1-6)
class ObjectDetailScreen extends ConsumerWidget {

  const ObjectDetailScreen({
    super.key,
    required this.objectId,
  });
  final String objectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ObjectDetailState state = ref.watch(objectDetailNotifierProvider(objectId));

    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      extendBody: true,
      body: Stack(
        children: <Widget>[
          const NebulaBackground(),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                // Custom Header (like HomeScreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: <Widget>[
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
                      ? const Center(child: CosmicLoader())
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
                                      colors: <Color>[Colors.transparent, Colors.white],
                                      stops: <double>[0, 0.05],
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
                                      children: <Widget>[
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
  Widget _buildHeader(CelestialObject object) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Hero Icon
        Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: object.iconPath.isNotEmpty
                  ? Image.asset(
                      object.iconPath,
                      width: 180,
                      height: 180,
                    )
                  : Image.asset(
                      _getDefaultIconForType(object.type),
                      width: 180,
                      height: 180,
                    ),
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
    final CelestialObject object = state.object!;
    
    // Use riseSetProvider for consistent data with cards
    final AsyncValue<Map<String, DateTime?>> riseSetAsync = ref.watch(riseSetProvider(object));
    
    final Map<String, DateTime?> times = riseSetAsync.valueOrNull ?? <String, DateTime?>{'rise': null, 'set': null};
    final DateTime? riseTime = times['rise'];
    final DateTime? setTime = times['set'];

    final String rise = riseTime != null ? DateFormat('HH:mm').format(riseTime) : '-- : --';
    final String set = setTime != null ? DateFormat('HH:mm').format(setTime) : '-- : --';
    final String offset = ref.watch(locationOffsetLabelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
              children: <Widget>[
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
            children: <Widget>[
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
            children: <Widget>[
              const Text(
                'Rise/Set Times',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    '↑ $rise | ↓ $set',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      offset,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDefaultIconForType(CelestialType type) {
    switch (type) {
      case CelestialType.planet:
      case CelestialType.satellite:
        return 'assets/icons/stars/star.webp'; // Fallback for planets/satellites
      case CelestialType.star:
        return 'assets/icons/stars/star.webp';
      case CelestialType.constellation:
        return 'assets/icons/stars/star.webp'; // Fallback for constellations
      case CelestialType.galaxy:
        return 'assets/icons/galaxy/andromeda.webp';
      case CelestialType.nebula:
        return 'assets/icons/nebula/orion_nebula.webp';
      case CelestialType.cluster:
        return 'assets/icons/cluster/pleidas.webp';
    }
  }
}