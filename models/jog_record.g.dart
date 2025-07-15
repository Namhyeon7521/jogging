// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jog_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JogRecordAdapter extends TypeAdapter<JogRecord> {
  @override
  final int typeId = 0;

  @override
  JogRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JogRecord(
      date: fields[0] as DateTime,
      distanceKm: fields[1] as double,
      durationSeconds: fields[2] as int,
      speedKmph: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, JogRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.distanceKm)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.speedKmph);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JogRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
