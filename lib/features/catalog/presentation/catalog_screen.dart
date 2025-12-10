import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../app/theme/app_theme.dart';
import 'package:astr/core/widgets/glass_panel.dart';
import '../../dashboard/presentation/widgets/nebula_background.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background (Nebula Gradient)
          const NebulaBackground(),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Celestial Catalog',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Ionicons.search, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 12),
                        Text(
                          'Search objects...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', true),
                        _buildCategoryChip('Planets', false),
                        _buildCategoryChip('Stars', false),
                        _buildCategoryChip('Deep Sky', false),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // List
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassPanel(
                            enableBlur: false,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Ionicons.planet, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Object ${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Constellation • Mag 1.2',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Icon(
                                  Ionicons.chevron_forward,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
