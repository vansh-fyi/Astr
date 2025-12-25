import 'package:hive_ce/hive.dart';

part 'saved_location.g.dart';

@HiveType(typeId: 1)
class SavedLocation {

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.bortleClass,
    required this.createdAt,
    this.placeName,
  });
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final double? bortleClass;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? placeName;
}
