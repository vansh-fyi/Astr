import 'package:equatable/equatable.dart';

class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? name;
  final String? placeName;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.placeName,
  });

  @override
  List<Object?> get props => [latitude, longitude, name, placeName];

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? placeName,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      placeName: placeName ?? this.placeName,
    );
  }
}
