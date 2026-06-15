// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farmer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FarmerModelAdapter extends TypeAdapter<FarmerModel> {
  @override
  final int typeId = 0;

  @override
  FarmerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FarmerModel(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      age: fields[3] as int,
      village: fields[4] as String,
      areaHa: fields[5] as double,
      notes: fields[6] as String?,
      gpsLat: fields[7] as double?,
      gpsLng: fields[8] as double?,
      photoUrl: fields[9] as String?,
      stage: fields[10] as String,
      isDeleted: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FarmerModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.village)
      ..writeByte(5)
      ..write(obj.areaHa)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.gpsLat)
      ..writeByte(8)
      ..write(obj.gpsLng)
      ..writeByte(9)
      ..write(obj.photoUrl)
      ..writeByte(10)
      ..write(obj.stage)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
