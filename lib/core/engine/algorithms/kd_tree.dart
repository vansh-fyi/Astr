import 'dart:math' as math;

/// Node for 2D KD-Tree
class KDNode {

  KDNode({
    required this.lat,
    required this.lon,
    required this.bortle,
    this.left,
    this.right,
  });
  final double lat;
  final double lon;
  final int bortle;
  KDNode? left;
  KDNode? right;
}

/// 2-Dimensional K-D Tree for geospatial points
/// specialized for (Lat, Lon) nearest neighbor search.
class KDTree {

  KDTree(this.root);

  /// Build a tree from a flat list of [lat, lon, bortle, ...]
  factory KDTree.fromFlatList(List<dynamic> data) {
    final List<_Point> points = <_Point>[];
    for (int i = 0; i < data.length; i += 3) {
      points.add(_Point(
        lat: (data[i] as num).toDouble(), 
        lon: (data[i + 1] as num).toDouble(), 
        bortle: (data[i + 2] as num).toInt(),
      ));
    }
    return KDTree(_buildRecursive(points, 0));
  }
  KDNode? root;

  static KDNode? _buildRecursive(List<_Point> points, int depth) {
    if (points.isEmpty) return null;

    final int axis = depth % 2; // 0 = lat, 1 = lon
    
    // Sort points by current axis to find median
    points.sort((_Point a, _Point b) => axis == 0 
        ? a.lat.compareTo(b.lat) 
        : a.lon.compareTo(b.lon));

    final int medianIndex = points.length ~/ 2;
    final _Point median = points[medianIndex];

    return KDNode(
      lat: median.lat,
      lon: median.lon,
      bortle: median.bortle,
      left: _buildRecursive(points.sublist(0, medianIndex), depth + 1),
      right: _buildRecursive(points.sublist(medianIndex + 1), depth + 1),
    );
  }

  /// Find nearest neighbor within maxDistanceKm
  /// Returns null if no point is within maxDistanceKm
  KDNode? nearest(double lat, double lon, double maxDistanceKm) {
    if (root == null) return null;
    
    return _nearestRecursive(
      root!, 
      lat, 
      lon, 
      maxDistanceKm, 
      0, 
      null, 
      double.infinity
    );
  }

  KDNode? _nearestRecursive(
    KDNode node,
    double targetLat,
    double targetLon,
    double maxDistKm,
    int depth,
    KDNode? bestNode,
    double bestDistKm,
  ) {
    // Calculate distance to current node
    final double dist = _haversine(targetLat, targetLon, node.lat, node.lon);
    
    // Update best if current is closer (and valid)
    if (dist < bestDistKm) { // We update bestDist regardless of maxDist to find absolute nearest, check maxDist at end?
       // Wait, req says "within X km". If best valid is > X, return null.
       // So we track best absolute, but only return if <= max.
       bestDistKm = dist;
       bestNode = node;
    }

    final int axis = depth % 2;
    final double diff = axis == 0 ? targetLat - node.lat : targetLon - node.lon;

    // Determine which side to search first
    final KDNode? near = diff <= 0 ? node.left : node.right;
    final KDNode? far = diff <= 0 ? node.right : node.left;

    // Search near side
    if (near != null) {
      final KDNode? result = _nearestRecursive(near, targetLat, targetLon, maxDistKm, depth + 1, bestNode, bestDistKm);
      if (result != null) {
          final double d = _haversine(targetLat, targetLon, result.lat, result.lon);
          if (d < bestDistKm) {
              bestDistKm = d;
              bestNode = result;
          }
      }
    }

    // Check if we need to search far side
    // We check if the splitting plane is within bestDistKm
    // Approximate 1 deg lat = 111km. 1 deg lon varies.
    // For simplicity/correctness, we should use Haversine logic or simplifying assumption.
    // However, for Lat/Lon KD-Trees, "distance to plane" is tricky due to spherical geometry.
    // But for "offline bortle", Euclidean approximation for tree traversal is often acceptable 
    // IF the data density is high.
    // Let's use simple degree distance for plane check to be safe, or just convert Km to Degrees approx.
    // 10km is approx 0.1 degrees.
    
    // Convert bestDistKm to rough degrees for plane check (conservative estimate)
    // 1 deg ~ 111km. So diff (deg) * 111 approx= dist (km)
    final double planeDistKm = diff.abs() * 111.0 * math.cos(math.min(targetLat.abs(), 80) * math.pi / 180); 
    // Cos lat factor for longitude. For Lat (axis 0), cos factor is 1.

    // Better: Just use 1 deg = 111km as upper bound for safety.
    // diff is in degrees.
    // distance to split plane in km approx:
    double distToPlane = diff.abs() * 111.32; // Latitude
    if (axis == 1) { // Longitude
        distToPlane = diff.abs() * 40075.0 * math.cos(targetLat * math.pi / 180) / 360.0;
    }

    if (distToPlane < bestDistKm && far != null) {
       final KDNode? result = _nearestRecursive(far, targetLat, targetLon, maxDistKm, depth + 1, bestNode, bestDistKm);
       if (result != null) {
          final double d = _haversine(targetLat, targetLon, result.lat, result.lon);
          if (d < bestDistKm) {
              bestDistKm = d;
              bestNode = result;
          }
      }
    }
    
    if (bestDistKm <= maxDistKm) return bestNode;
    return null;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth radius in km
    final double phi1 = lat1 * math.pi / 180;
    final double phi2 = lat2 * math.pi / 180;
    final double deltaPhi = (lat2 - lat1) * math.pi / 180;
    final double deltaLambda = (lon2 - lon1) * math.pi / 180;

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
        math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return r * c;
  }
}

class _Point {
  _Point({required this.lat, required this.lon, required this.bortle});
  final double lat;
  final double lon;
  final int bortle;
}
