// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CropEventModelAdapter extends TypeAdapter<CropEventModel> {
  @override
  final int typeId = 3;

  @override
  CropEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CropEventModel(
      id: fields[0] as String,
      seasonId: fields[1] as String,
      eventType: fields[2] as String,
      eventDate: fields[3] as DateTime,
      nitrogenKg: fields[4] as double,
      phosphorusKg: fields[5] as double,
      potassiumKg: fields[6] as double,
      organicNKg: fields[7] as double,
      dieselL: fields[8] as double,
      electricityKwh: fields[9] as double,
      irrigationL: fields[10] as double,
      harvestYieldT: fields[11] as double?,
      notes: fields[12] as String?,
      createdAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CropEventModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.seasonId)
      ..writeByte(2)
      ..write(obj.eventType)
      ..writeByte(3)
      ..write(obj.eventDate)
      ..writeByte(4)
      ..write(obj.nitrogenKg)
      ..writeByte(5)
      ..write(obj.phosphorusKg)
      ..writeByte(6)
      ..write(obj.potassiumKg)
      ..writeByte(7)
      ..write(obj.organicNKg)
      ..writeByte(8)
      ..write(obj.dieselL)
      ..writeByte(9)
      ..write(obj.electricityKwh)
      ..writeByte(10)
      ..write(obj.irrigationL)
      ..writeByte(11)
      ..write(obj.harvestYieldT)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
