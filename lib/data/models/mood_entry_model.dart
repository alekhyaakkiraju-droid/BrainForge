import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntryModel {
  const MoodEntryModel({
    required this.id,
    required this.profileId,
    required this.mood,
    required this.intensity,
    required this.recordedAt,
    this.sessionId,
  });

  factory MoodEntryModel.fromJson(Map<String, dynamic> json) =>
      MoodEntryModel(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        mood: json['mood'] as String,
        intensity: (json['intensity'] as num).toInt(),
        recordedAt: _parseTimestamp(json['recordedAt']),
        sessionId: json['sessionId'] as String?,
      );

  final String id;
  final String profileId;

  /// One of: happy | okay | tired | frustrated | excited.
  final String mood;

  /// Scale of 1–5.
  final int intensity;
  final DateTime recordedAt;
  final String? sessionId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'mood': mood,
        'intensity': intensity,
        'recordedAt': Timestamp.fromDate(recordedAt),
        'sessionId': sessionId,
      };
}

DateTime _parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse timestamp: $value');
}
