import 'package:cloud_firestore/cloud_firestore.dart';

class XpRecordModel {
  const XpRecordModel({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.source,
    required this.description,
    required this.earnedAt,
    this.questId,
  });

  factory XpRecordModel.fromJson(Map<String, dynamic> json) => XpRecordModel(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        amount: (json['amount'] as num).toInt(),
        source: json['source'] as String,
        description: json['description'] as String,
        earnedAt: _parseTimestamp(json['earnedAt']),
        questId: json['questId'] as String?,
      );

  final String id;
  final String profileId;
  final int amount;

  /// One of: quest | bonus | streak | badge.
  final String source;
  final String description;
  final DateTime earnedAt;
  final String? questId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'amount': amount,
        'source': source,
        'description': description,
        'earnedAt': Timestamp.fromDate(earnedAt),
        'questId': questId,
      };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
