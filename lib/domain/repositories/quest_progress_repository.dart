import '../../data/models/quest_progress_model.dart';

/// Persists and retrieves step-completion progress for a quest.
abstract interface class QuestProgressRepository {
  /// Loads saved progress or returns `null` if no progress exists yet.
  Future<QuestProgressModel?> getProgress(
    String profileId,
    String questId,
  );

  /// Persists [progress], creating or overwriting the existing record.
  Future<void> saveProgress(QuestProgressModel progress);
}
