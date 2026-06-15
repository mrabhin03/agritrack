// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlotModelAdapter extends TypeAdapter<PlotModel> {
  @override
  final int typeId = 1;

  @override
  PlotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlotModel(
      id: fields[0] as String,
      farmerId: fields[1] as String,
      name: fields[2] as String,
      boundary: (fields[3] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList(),
      areaHa: fields[4] as double,
      soilType: fields[5] as String,
      irrigation: fields[6] as String,
      crop: fields[7] as String,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlotModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farmerId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.boundary)
      ..writeByte(4)
      ..write(obj.areaHa)
      ..writeByte(5)
      ..write(obj.soilType)
      ..writeByte(6)
      ..write(obj.irrigation)
      ..writeByte(7)
      ..write(obj.crop)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
