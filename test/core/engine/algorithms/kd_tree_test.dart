
import 'package:flutter_test/flutter_test.dart';
import 'package:astr/core/engine/algorithms/kd_tree.dart';

void main() {
  group('KDTree Tests', () {
    test('Builds tree from flat list', () {
      final data = [
        10.0, 10.0, 1, // Point A
        20.0, 20.0, 2, // Point B
        30.0, 30.0, 3, // Point C
      ];
      final tree = KDTree.fromFlatList(data);
      expect(tree.root, isNotNull);
    });

    test('Finds exact match', () {
      final data = [
        10.0, 10.0, 1,
        20.0, 20.0, 2,
        30.0, 30.0, 3,
      ];
      final tree = KDTree.fromFlatList(data);
      final result = tree.nearest(10.0, 10.0, 5.0);
      
      expect(result, isNotNull);
      expect(result!.lat, 10.0);
      expect(result.lon, 10.0);
      expect(result.bortle, 1);
    });

    test('Finds nearest neighbor within valid range', () {
      final data = [
        10.0, 10.0, 1, // Far
        10.1, 10.1, 8, // Near (approx 15km depending on lat)
        10.001, 10.001, 9, // Very Near (approx 150m)
      ];
      final tree = KDTree.fromFlatList(data);
      
      // Search at 10.0, 10.0 with 50km range
      // Should find 10.0, 10.0 (dist 0) - wait, if input is 10.0, 10.0
      
      // Let's search at 10.002, 10.002
      // Dist to 10.001, 10.001 is small (~150m)
      // Dist to 10.1, 10.1 is larger (~15km)
      
      final result = tree.nearest(10.002, 10.002, 10.0); // 10km max
      
      expect(result, isNotNull);
      expect(result!.bortle, 9);
    });

    test('Returns null if nearest is out of max range', () {
      final data = [
        10.0, 10.0, 1,
      ];
      final tree = KDTree.fromFlatList(data);
      
      // Search from 11.0, 11.0 (~150km away)
      final result = tree.nearest(11.0, 11.0, 50.0); // 50km max
      
      expect(result, isNull);
    });
    
    test('Delhi Fallback Verification Logic', () {
       // Simulate the points we added to fallback
       final data = [
          28.6139, 77.2090, 8, // Delhi
          40.7128, -74.0060, 9, // NYC
       ];
       final tree = KDTree.fromFlatList(data);
       
       // Search near Delhi (Connaught Place)
       // 28.6304° N, 77.2177° E. Dist to 28.6139, 77.2090 is ~2km.
       final result = tree.nearest(28.6304, 77.2177, 10.0);
       
       expect(result, isNotNull);
       expect(result!.bortle, 8);
    });
  });
}
