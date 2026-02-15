// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeatherCacheEntryAdapter extends TypeAdapter<WeatherCacheEntry> {
  @override
  final typeId = 4;

  @override
  WeatherCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeatherCacheEntry(
      h3Index: fields[0] as String,
      date: fields[1] as DateTime,
      jsonData: fields[2] as String,
      fetchedAt: fields[3] as DateTime,
      cacheKey: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WeatherCacheEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.h3Index)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.jsonData)
      ..writeByte(3)
      ..write(obj.fetchedAt)
      ..writeByte(4)
      ..write(obj.cacheKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
