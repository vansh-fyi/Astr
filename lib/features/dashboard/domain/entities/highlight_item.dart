import 'package:astr/features/astronomy/domain/entities/celestial_body.dart';

class HighlightItem {
  final CelestialBody body;
  final double altitude;
  final double magnitude;
  final bool isVisible;

  const HighlightItem({
    required this.body,
    required this.altitude,
    required this.magnitude,
    required this.isVisible,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is HighlightItem &&
      other.body == body &&
      other.altitude == altitude &&
      other.magnitude == magnitude &&
      other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return body.hashCode ^
      altitude.hashCode ^
      magnitude.hashCode ^
      isVisible.hashCode;
  }
}
