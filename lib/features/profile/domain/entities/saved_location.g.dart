// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedLocationAdapter extends TypeAdapter<SavedLocation> {
  @override
  final typeId = 1;

  @override
  SavedLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedLocation(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: (fields[2] as num).toDouble(),
      longitude: (fields[3] as num).toDouble(),
      bortleClass: (fields[4] as num?)?.toDouble(),
      createdAt: fields[5] as DateTime,
      placeName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedLocation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.bortleClass)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.placeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
