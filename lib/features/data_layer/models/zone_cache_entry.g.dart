// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ZoneCacheEntryAdapter extends TypeAdapter<ZoneCacheEntry> {
  @override
  final typeId = 5;

  @override
  ZoneCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ZoneCacheEntry(
      h3Index: fields[0] as String,
      bortleClass: (fields[1] as num).toInt(),
      ratio: (fields[2] as num).toDouble(),
      sqm: (fields[3] as num).toDouble(),
      fetchedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ZoneCacheEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.h3Index)
      ..writeByte(1)
      ..write(obj.bortleClass)
      ..writeByte(2)
      ..write(obj.ratio)
      ..writeByte(3)
      ..write(obj.sqm)
      ..writeByte(4)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoneCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
