import 'package:hive/hive.dart';

import '../../domain/entities/child_profile.dart';

// TypeAdapter typeId registry:
//   0 = ChildProfileModel
@HiveType(typeId: 0)
class ChildProfileModel extends HiveObject {
  ChildProfileModel({
    required this.id,
    required this.displayName,
    required this.ageRangeIndex,
    required this.activeModeIndex,
    required this.totalXp,
    this.avatarAssetPath,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  int ageRangeIndex;

  @HiveField(3)
  int activeModeIndex;

  @HiveField(4)
  int totalXp;

  @HiveField(5)
  String? avatarAssetPath;

  ChildProfile toDomain() => ChildProfile(
        id: id,
        displayName: displayName,
        ageRange: AgeRange.values[ageRangeIndex],
        activeMode: AppMode.values[activeModeIndex],
        totalXp: totalXp,
        avatarAssetPath: avatarAssetPath,
      );

  static ChildProfileModel fromDomain(ChildProfile profile) =>
      ChildProfileModel(
        id: profile.id,
        displayName: profile.displayName,
        ageRangeIndex: profile.ageRange.index,
        activeModeIndex: profile.activeMode.index,
        totalXp: profile.totalXp,
        avatarAssetPath: profile.avatarAssetPath,
      );
}

/// Hand-authored Hive TypeAdapter — replaces code-gen output.
class ChildProfileModelAdapter extends TypeAdapter<ChildProfileModel> {
  @override
  final int typeId = 0;

  @override
  ChildProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChildProfileModel(
      id: fields[0] as String,
      displayName: fields[1] as String,
      ageRangeIndex: fields[2] as int,
      activeModeIndex: fields[3] as int,
      totalXp: fields[4] as int,
      avatarAssetPath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChildProfileModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.ageRangeIndex)
      ..writeByte(3)
      ..write(obj.activeModeIndex)
      ..writeByte(4)
      ..write(obj.totalXp)
      ..writeByte(5)
      ..write(obj.avatarAssetPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
