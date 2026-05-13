import 'package:equatable/equatable.dart';

/// Represents a child's profile within BrainForge.
///
/// COPPA compliance: no precise birthdate, location, or photos stored here.
/// [ageRange] replaces exact age; all PII fields are in the parent account.
enum AgeRange { ages6to8, ages9to11, ages12to14 }

enum AppMode { school, summer }

class ChildProfile extends Equatable {
  const ChildProfile({
    required this.id,
    required this.displayName,
    required this.ageRange,
    required this.activeMode,
    required this.totalXp,
    this.avatarAssetPath,
  });

  final String id;
  final String displayName;
  final AgeRange ageRange;
  final AppMode activeMode;
  final int totalXp;
  final String? avatarAssetPath;

  ChildProfile copyWith({
    String? id,
    String? displayName,
    AgeRange? ageRange,
    AppMode? activeMode,
    int? totalXp,
    String? avatarAssetPath,
  }) =>
      ChildProfile(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        ageRange: ageRange ?? this.ageRange,
        activeMode: activeMode ?? this.activeMode,
        totalXp: totalXp ?? this.totalXp,
        avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      );

  @override
  List<Object?> get props =>
      [id, displayName, ageRange, activeMode, totalXp, avatarAssetPath];
}
