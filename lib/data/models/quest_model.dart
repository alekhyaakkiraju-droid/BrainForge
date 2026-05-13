import 'package:cloud_firestore/cloud_firestore.dart';

class QuestModel {
  const QuestModel({
    required this.id,
    required this.assignedToProfileId,
    required this.title,
    required this.description,
    required this.subject,
    required this.durationMinutes,
    required this.xpReward,
    required this.status,
    required this.timeOfDay,
    required this.createdAt,
    this.scheduledFor,
    this.completedAt,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
        id: json['id'] as String,
        assignedToProfileId: json['assignedToProfileId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subject: json['subject'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        xpReward: (json['xpReward'] as num).toInt(),
        status: json['status'] as String,
        timeOfDay: json['timeOfDay'] as String,
        createdAt: _parseTimestamp(json['createdAt']),
        scheduledFor: json['scheduledFor'] != null
            ? _parseTimestamp(json['scheduledFor'])
            : null,
        completedAt: json['completedAt'] != null
            ? _parseTimestamp(json['completedAt'])
            : null,
      );

  final String id;
  final String assignedToProfileId;
  final String title;
  final String description;
  final String subject;
  final int durationMinutes;
  final int xpReward;

  /// One of: pending | active | completed | skipped.
  final String status;

  /// One of: morning | afternoon | evening.
  final String timeOfDay;
  final DateTime? scheduledFor;
  final DateTime? completedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignedToProfileId': assignedToProfileId,
        'title': title,
        'description': description,
        'subject': subject,
        'durationMinutes': durationMinutes,
        'xpReward': xpReward,
        'status': status,
        'timeOfDay': timeOfDay,
        'scheduledFor':
            scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
