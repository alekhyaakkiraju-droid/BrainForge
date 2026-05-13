import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  const SessionModel({
    required this.id,
    required this.profileId,
    required this.startedAt,
    required this.durationSeconds,
    required this.wasCompleted,
    this.questId,
    this.endedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        startedAt: _parseTimestamp(json['startedAt']),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        wasCompleted: json['wasCompleted'] as bool,
        questId: json['questId'] as String?,
        endedAt: json['endedAt'] != null
            ? _parseTimestamp(json['endedAt'])
            : null,
      );

  final String id;
  final String profileId;
  final String? questId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final bool wasCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'questId': questId,
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'durationSeconds': durationSeconds,
        'wasCompleted': wasCompleted,
      };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
