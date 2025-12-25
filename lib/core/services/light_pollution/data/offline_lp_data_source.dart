import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../engine/algorithms/kd_tree.dart';
import '../../../engine/models/location.dart';

/// Offline data source for light pollution data
/// Reads Bortle class from local PNG asset using pixel color mapping
/// Based on David Lorenz's Light Pollution Atlas color scheme
class OfflineLPDataSource {
  img.Image? _cachedImage;
  bool _isLoading = false;

  /// Path to the light pollution map PNG asset
  static const String _assetPath = 'assets/maps/world2024_low3.png';

  /// Reference colors for Lorenz Light Pollution Zones
  /// These map to approximate Bortle Scale equivalents (1-9)
  /// Color progression: Dark Blue → Light Blue → Green → Yellow → Orange → Red → White
  static final List<_ZoneColor> _zoneColors = <_ZoneColor>[
    // Zone 0-1: Dark Blue (Bortle 1 - Excellent dark sky)
    const _ZoneColor(rgb: <int>[0, 0, 50], bortle: 1),    // Very dark blue
    const _ZoneColor(rgb: <int>[0, 24, 73], bortle: 1),   // Dark blue
    
    // Zone 2: Light Blue (Bortle 2 - Typical dark sky)
    const _ZoneColor(rgb: <int>[0, 61, 102], bortle: 2),  // Medium blue
    const _ZoneColor(rgb: <int>[0, 85, 127], bortle: 2),  // Light blue
    
    // Zone 3: Green (Bortle 3-4 - Rural sky)
    const _ZoneColor(rgb: <int>[0, 110, 51], bortle: 3),  // Dark green
    const _ZoneColor(rgb: <int>[61, 153, 61], bortle: 4), // Light green
    
    // Zone 4: Yellow (Bortle 4-5 - Rural/suburban transition)
    const _ZoneColor(rgb: <int>[153, 153, 0], bortle: 4), // Dark yellow
    const _ZoneColor(rgb: <int>[204, 204, 0], bortle: 5), // Light yellow
    
    // Zone 5: Orange (Bortle 5-6 - Suburban sky)
    const _ZoneColor(rgb: <int>[204, 102, 0], bortle: 5), // Dark orange
    const _ZoneColor(rgb: <int>[255, 153, 51], bortle: 6), // Light orange
    
    // Zone 6-7: Red (Bortle 6-8 - Urban sky)
    const _ZoneColor(rgb: <int>[204, 0, 0], bortle: 7),   // Dark red
    const _ZoneColor(rgb: <int>[255, 51, 51], bortle: 8), // Light red
    
    // Zone 8-9: White/Pink (Bortle 8-9 - Inner city)
    const _ZoneColor(rgb: <int>[255, 153, 153], bortle: 8), // Pink
    const _ZoneColor(rgb: <int>[255, 204, 204], bortle: 9), // Light pink
    const _ZoneColor(rgb: <int>[255, 255, 255], bortle: 9), // White - extreme pollution
  ];

  /// Get Bortle class from offline PNG map
  /// Returns null if asset loading fails or coordinates are invalid
  KDTree? _kdTree;
  bool _isTreeLoading = false;
  static const String _cityDbPath = 'assets/db/cities.json';

  /// Get Bortle class from offline sources (City DB -> Map)
  /// Returns null if both fail or coordinates are invalid
  Future<int?> getBortleClass(Location location) async {
    try {
      // 1. Try City Database (KD-Tree)
      if (_kdTree == null && !_isTreeLoading) {
        _isTreeLoading = true;
        await _loadCityData();
        _isTreeLoading = false;
      }
      
      // Wait if loading (for edge cases where multiple calls happen at startup)
      // Simple loop to avoid complex mutex for this scope
      int retries = 0;
      while (_isTreeLoading && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }

      if (_kdTree != null) {
        // Search for nearest city within 10km
        final KDNode? nearest = _kdTree!.nearest(location.latitude, location.longitude, 10);
        if (nearest != null) {
          return nearest.bortle;
        }
      }
    } catch (e) {
      // Continue to map fallback on error
      print('KD-Tree lookup failed: $e');
    }

    // 2. Fallback to Image Map
    try {
      if (_cachedImage == null && !_isLoading) {
        _isLoading = true;
        final Uint8List? bytes = await _loadImageBytes();
        if (bytes == null) {
          _isLoading = false;
          return null;
        }
        _cachedImage = img.decodeImage(bytes);
        _isLoading = false;
      }

      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (_cachedImage == null) return null;

      final img.Image image = _cachedImage!;
      final int x = ((location.longitude + 180) * (image.width / 360)).toInt();
      final int y = ((90 - location.latitude) * (image.height / 180)).toInt();

      if (x < 0 || x >= image.width || y < 0 || y >= image.height) return null;

      return _colorToBortleClass(image.getPixel(x, y));
    } catch (e) {
      return null;
    }
  }

  /// Load and parse city database
  Future<void> _loadCityData() async {
    try {
      String? jsonString;
      try {
        // Try file first (tests)
        final File file = File(_cityDbPath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
        }
      } catch (_) {}

      jsonString ??= await rootBundle.loadString(_cityDbPath);

      final List<dynamic> data = jsonDecode(jsonString);
      _kdTree = KDTree.fromFlatList(data);
    } catch (e) {
      print('Error loading city DB: $e');
    }
  }

  /// Map pixel color to Bortle class (1-9) using nearest-color matching
  /// Based on David Lorenz's Light Pollution Zone color scheme
  int _colorToBortleClass(img.Pixel pixel) {
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();

    // Find nearest zone color using Euclidean distance in RGB space
    double minDist = double.infinity;
    int bestBortle = 5; // Default to mid-range if no good match

    for (final _ZoneColor zone in _zoneColors) {
      final int dr = r - zone.rgb[0];
      final int dg = g - zone.rgb[1];
      final int db = b - zone.rgb[2];
      final double dist = math.sqrt(dr * dr + dg * dg + db * db);

      if (dist < minDist) {
        minDist = dist;
        bestBortle = zone.bortle;
      }
    }

    return bestBortle;
  }

  /// Clear cached image (for testing or memory management)
  void clearCache() {
    _cachedImage = null;
    _isLoading = false;
    _kdTree = null;
  }

  /// Load image bytes with fallback strategy
  /// Try File (for tests), fallback to rootBundle (for production)
  Future<Uint8List?> _loadImageBytes() async {
    try {
      // Try File (works in tests)
      final File file = File(_assetPath);
      if (await file.exists()) {
        final Uint8List bytes = await file.readAsBytes();
        return Uint8List.fromList(bytes);
      }
    } catch (_) {
      // Ignore file read errors, try rootBundle
    }

    try {
      // Fallback to rootBundle (works in production)
      final ByteData data = await rootBundle.load(_assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// Helper class to store zone color and corresponding Bortle class
class _ZoneColor {
  
  const _ZoneColor({required this.rgb, required this.bortle});
  final List<int> rgb;
  final int bortle;
}
