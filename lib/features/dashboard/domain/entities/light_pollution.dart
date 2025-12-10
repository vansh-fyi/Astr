import 'package:equatable/equatable.dart';

enum LightPollutionSource {
  precise, // From Binary Tile
  fallback, // From PNG Map
  estimated, // No data, rough estimate
}

class LightPollution extends Equatable {
  final int visibilityIndex; // 0-9 (Mapped from Bortle/Brightness)
  final double brightnessRatio; // Artificial / Natural brightness
  final double mpsas; // Magnitudes per square arc-second
  final LightPollutionSource source;
  final String zone; // e.g. "4b"

  const LightPollution({
    required this.visibilityIndex,
    required this.brightnessRatio,
    required this.mpsas,
    required this.source,
    required this.zone,
  });

  @override
  List<Object?> get props => [visibilityIndex, brightnessRatio, mpsas, source, zone];
  
  // Factory for empty/unknown state
  factory LightPollution.unknown() {
    return const LightPollution(
      visibilityIndex: 0,
      brightnessRatio: 0.0,
      mpsas: 22.0, // Pristine sky
      source: LightPollutionSource.estimated,
      zone: "0",
    );
  }

  factory LightPollution.fromJson(Map<String, dynamic> json) {
    final bortle = (json['bortle_class'] ?? json['bortle']) as int? ?? 0;
    final isFallback = json['fallback'] == true;
    return LightPollution(
      visibilityIndex: bortle,
      brightnessRatio: 0.0, // Not provided by API yet
      mpsas: (json['mpsas'] as num?)?.toDouble() ?? 22.0,
      source: isFallback ? LightPollutionSource.fallback : LightPollutionSource.precise,
      zone: bortle.toString(),
    );
  }
}
