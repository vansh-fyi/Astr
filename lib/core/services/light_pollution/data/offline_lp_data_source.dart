import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:astr/core/engine/models/location.dart';
import 'dart:convert';
import 'package:astr/core/engine/algorithms/kd_tree.dart';
import 'package:image/image.dart' as img;

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
  static final List<_ZoneColor> _zoneColors = [
    // Zone 0-1: Dark Blue (Bortle 1 - Excellent dark sky)
    _ZoneColor(rgb: [0, 0, 50], bortle: 1),    // Very dark blue
    _ZoneColor(rgb: [0, 24, 73], bortle: 1),   // Dark blue
    
    // Zone 2: Light Blue (Bortle 2 - Typical dark sky)
    _ZoneColor(rgb: [0, 61, 102], bortle: 2),  // Medium blue
    _ZoneColor(rgb: [0, 85, 127], bortle: 2),  // Light blue
    
    // Zone 3: Green (Bortle 3-4 - Rural sky)
    _ZoneColor(rgb: [0, 110, 51], bortle: 3),  // Dark green
    _ZoneColor(rgb: [61, 153, 61], bortle: 4), // Light green
    
    // Zone 4: Yellow (Bortle 4-5 - Rural/suburban transition)
    _ZoneColor(rgb: [153, 153, 0], bortle: 4), // Dark yellow
    _ZoneColor(rgb: [204, 204, 0], bortle: 5), // Light yellow
    
    // Zone 5: Orange (Bortle 5-6 - Suburban sky)
    _ZoneColor(rgb: [204, 102, 0], bortle: 5), // Dark orange
    _ZoneColor(rgb: [255, 153, 51], bortle: 6), // Light orange
    
    // Zone 6-7: Red (Bortle 6-8 - Urban sky)
    _ZoneColor(rgb: [204, 0, 0], bortle: 7),   // Dark red
    _ZoneColor(rgb: [255, 51, 51], bortle: 8), // Light red
    
    // Zone 8-9: White/Pink (Bortle 8-9 - Inner city)
    _ZoneColor(rgb: [255, 153, 153], bortle: 8), // Pink
    _ZoneColor(rgb: [255, 204, 204], bortle: 9), // Light pink
    _ZoneColor(rgb: [255, 255, 255], bortle: 9), // White - extreme pollution
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
        final nearest = _kdTree!.nearest(location.latitude, location.longitude, 10.0);
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
        final bytes = await _loadImageBytes();
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

      final image = _cachedImage!;
      final x = ((location.longitude + 180) * (image.width / 360)).toInt();
      final y = ((90 - location.latitude) * (image.height / 180)).toInt();

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
        final file = File(_cityDbPath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
        }
      } catch (_) {}

      if (jsonString == null) {
        // Fallback to asset bundle
        jsonString = await rootBundle.loadString(_cityDbPath);
      }

      final List<dynamic> data = jsonDecode(jsonString);
      _kdTree = KDTree.fromFlatList(data);
    } catch (e) {
      print('Error loading city DB: $e');
    }
  }

  /// Map pixel color to Bortle class (1-9) using nearest-color matching
  /// Based on David Lorenz's Light Pollution Zone color scheme
  int _colorToBortleClass(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    // Find nearest zone color using Euclidean distance in RGB space
    double minDist = double.infinity;
    int bestBortle = 5; // Default to mid-range if no good match

    for (final zone in _zoneColors) {
      final dr = r - zone.rgb[0];
      final dg = g - zone.rgb[1];
      final db = b - zone.rgb[2];
      final dist = math.sqrt(dr * dr + dg * dg + db * db);

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
      final file = File(_assetPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return Uint8List.fromList(bytes);
      }
    } catch (_) {
      // Ignore file read errors, try rootBundle
    }

    try {
      // Fallback to rootBundle (works in production)
      final data = await rootBundle.load(_assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// Helper class to store zone color and corresponding Bortle class
class _ZoneColor {
  final List<int> rgb;
  final int bortle;
  
  const _ZoneColor({required this.rgb, required this.bortle});
}
