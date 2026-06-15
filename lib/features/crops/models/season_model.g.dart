// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SeasonModelAdapter extends TypeAdapter<SeasonModel> {
  @override
  final int typeId = 2;

  @override
  SeasonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SeasonModel(
      id: fields[0] as String,
      farmerId: fields[1] as String,
      plotId: fields[2] as String?,
      variety: fields[3] as String,
      plantingDate: fields[4] as DateTime,
      harvestDate: fields[5] as DateTime,
      targetYieldTHa: fields[6] as double,
      status: fields[7] as String,
      stage: fields[8] as String,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SeasonModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmerId)
      ..writeByte(2)
      ..write(obj.plotId)
      ..writeByte(3)
      ..write(obj.variety)
      ..writeByte(4)
      ..write(obj.plantingDate)
      ..writeByte(5)
      ..write(obj.harvestDate)
      ..writeByte(6)
      ..write(obj.targetYieldTHa)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.stage)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
