import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.profileId,
    required this.badgeType,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.unlockedAt,
    required this.xpBonus,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        badgeType: json['badgeType'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        iconAsset: json['iconAsset'] as String,
        unlockedAt: _parseTimestamp(json['unlockedAt']),
        xpBonus: (json['xpBonus'] as num).toInt(),
      );

  final String id;
  final String profileId;
  final String badgeType;
  final String title;
  final String description;
  final String iconAsset;
  final DateTime unlockedAt;
  final int xpBonus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'badgeType': badgeType,
        'title': title,
        'description': description,
        'iconAsset': iconAsset,
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'xpBonus': xpBonus,
      };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
