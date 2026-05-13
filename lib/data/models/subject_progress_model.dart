import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectProgressModel {
  const SubjectProgressModel({
    required this.id,
    required this.profileId,
    required this.subject,
    required this.completedQuests,
    required this.totalXp,
    required this.progressPercent,
    required this.lastActivityAt,
  });

  factory SubjectProgressModel.fromJson(Map<String, dynamic> json) =>
      SubjectProgressModel(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        subject: json['subject'] as String,
        completedQuests: (json['completedQuests'] as num).toInt(),
        totalXp: (json['totalXp'] as num).toInt(),
        progressPercent: (json['progressPercent'] as num).toDouble(),
        lastActivityAt: _parseTimestamp(json['lastActivityAt']),
      );

  final String id;
  final String profileId;
  final String subject;
  final int completedQuests;
  final int totalXp;

  /// 0.0–1.0 fraction towards the next milestone.
  final double progressPercent;
  final DateTime lastActivityAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'subject': subject,
        'completedQuests': completedQuests,
        'totalXp': totalXp,
        'progressPercent': progressPercent,
        'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      };
}

DateTime _parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
