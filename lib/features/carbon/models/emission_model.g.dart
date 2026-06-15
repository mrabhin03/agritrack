// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emission_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmissionModelAdapter extends TypeAdapter<EmissionModel> {
  @override
  final int typeId = 4;

  @override
  EmissionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmissionModel(
      id: fields[0] as String,
      seasonId: fields[1] as String,
      eventId: fields[2] as String?,
      n2oCo2eKg: fields[3] as double,
      dieselCo2eKg: fields[4] as double,
      electricityCo2eKg: fields[5] as double,
      areaHa: fields[6] as double,
      intensityPerHa: fields[7] as double?,
      intensityPerTonne: fields[8] as double?,
      calculatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EmissionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.seasonId)
      ..writeByte(2)
      ..write(obj.eventId)
      ..writeByte(3)
      ..write(obj.n2oCo2eKg)
      ..writeByte(4)
      ..write(obj.dieselCo2eKg)
      ..writeByte(5)
      ..write(obj.electricityCo2eKg)
      ..writeByte(6)
      ..write(obj.areaHa)
      ..writeByte(7)
      ..write(obj.intensityPerHa)
      ..writeByte(8)
      ..write(obj.intensityPerTonne)
      ..writeByte(9)
      ..write(obj.calculatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmissionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
