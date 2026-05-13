import 'package:hive/hive.dart';

import '../../domain/entities/child_profile.dart';

part 'child_profile_model.g.dart';

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
