import 'package:equatable/equatable.dart';
import 'geo_location.dart';

class AstrContext extends Equatable {
  final DateTime selectedDate;
  final GeoLocation location;
  final bool isCurrentLocation;

  const AstrContext({
    required this.selectedDate,
    required this.location,
    this.isCurrentLocation = true,
  });

  AstrContext copyWith({
    DateTime? selectedDate,
    GeoLocation? location,
    bool? isCurrentLocation,
  }) {
    return AstrContext(
      selectedDate: selectedDate ?? this.selectedDate,
      location: location ?? this.location,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    );
  }

  @override
  List<Object?> get props => [selectedDate, location, isCurrentLocation];
}
