import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.parentUid,
    required this.displayName,
    required this.avatarAsset,
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        parentUid: json['parentUid'] as String,
        displayName: json['displayName'] as String,
        avatarAsset: json['avatarAsset'] as String,
        xp: (json['xp'] as num).toInt(),
        level: (json['level'] as num).toInt(),
        currentStreak: (json['currentStreak'] as num).toInt(),
        longestStreak: (json['longestStreak'] as num).toInt(),
        mode: json['mode'] as String,
        createdAt: _parseTimestamp(json['createdAt']),
        updatedAt: _parseTimestamp(json['updatedAt']),
      );

  final String id;
  final String parentUid;
  final String displayName;
  final String avatarAsset;
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;

  /// Either 'school' or 'summer'.
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentUid': parentUid,
        'displayName': displayName,
        'avatarAsset': avatarAsset,
        'xp': xp,
        'level': level,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'mode': mode,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserProfileModel copyWith({
    String? id,
    String? parentUid,
    String? displayName,
    String? avatarAsset,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserProfileModel(
        id: id ?? this.id,
        parentUid: parentUid ?? this.parentUid,
        displayName: displayName ?? this.displayName,
        avatarAsset: avatarAsset ?? this.avatarAsset,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        mode: mode ?? this.mode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

DateTime _parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
