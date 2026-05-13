import 'package:cloud_firestore/cloud_firestore.dart';

class QuestSubmissionModel {
  const QuestSubmissionModel({
    required this.id,
    required this.questId,
    required this.profileId,
    required this.submittedAt,
    required this.durationSeconds,
    required this.xpEarned,
    this.moodAtStart,
    this.notes,
  });

  factory QuestSubmissionModel.fromJson(Map<String, dynamic> json) =>
      QuestSubmissionModel(
        id: json['id'] as String,
        questId: json['questId'] as String,
        profileId: json['profileId'] as String,
        submittedAt: _parseTimestamp(json['submittedAt']),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        xpEarned: (json['xpEarned'] as num).toInt(),
        moodAtStart: json['moodAtStart'] as String?,
        notes: json['notes'] as String?,
      );

  final String id;
  final String questId;
  final String profileId;
  final DateTime submittedAt;
  final int durationSeconds;
  final int xpEarned;
  final String? moodAtStart;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'questId': questId,
        'profileId': profileId,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'durationSeconds': durationSeconds,
        'xpEarned': xpEarned,
        'moodAtStart': moodAtStart,
        'notes': notes,
      };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
