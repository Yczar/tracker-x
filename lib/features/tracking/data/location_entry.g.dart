// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationEntryAdapter extends TypeAdapter<LocationEntry> {
  @override
  final int typeId = 1;

  @override
  LocationEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationEntry(
      trackerId: fields[0] as String,
      lat: fields[1] as double,
      lng: fields[2] as double,
      accuracy: fields[3] as double?,
      speed: fields[4] as double?,
      timestamp: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.trackerId)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lng)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.speed)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
