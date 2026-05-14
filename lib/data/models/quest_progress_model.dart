import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks which steps a student has completed in a given quest.
///
/// Stored at `questProgress/{profileId}_{questId}` so that progress
/// survives app restarts without requiring a running session.
class QuestProgressModel {
  const QuestProgressModel({
    required this.profileId,
    required this.questId,
    required this.completedStepIndices,
    required this.updatedAt,
  });

  factory QuestProgressModel.fromJson(Map<String, dynamic> json) =>
      QuestProgressModel(
        profileId: json['profileId'] as String,
        questId: json['questId'] as String,
        completedStepIndices:
            (json['completedStepIndices'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                const [],
        updatedAt: _parseTimestamp(json['updatedAt']),
      );

  /// The child's Firebase Auth UID.
  final String profileId;
  final String questId;

  /// 0-based indices of steps the student has completed.
  final List<int> completedStepIndices;
  final DateTime updatedAt;

  /// Firestore document ID derived from profile and quest IDs.
  String get docId => '${profileId}_$questId';

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'questId': questId,
        'completedStepIndices': completedStepIndices,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Returns the 0-based index of the next step to complete.
  int get nextStepIndex => completedStepIndices.length;

  QuestProgressModel withStepCompleted(int stepIndex) =>
      QuestProgressModel(
        profileId: profileId,
        questId: questId,
        completedStepIndices: [...completedStepIndices, stepIndex],
        updatedAt: DateTime.now(),
      );
}

DateTime _parseTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
