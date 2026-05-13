import '../../data/models/quest_submission_model.dart';

abstract interface class QuestSubmissionRepository {
  Future<QuestSubmissionModel?> getById(String id);
  Future<List<QuestSubmissionModel>> getByProfileId(String profileId);
  Future<List<QuestSubmissionModel>> getByQuestId(String questId);
  Future<void> save(QuestSubmissionModel submission);
  Future<void> delete(String id);
}
