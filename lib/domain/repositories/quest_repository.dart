import '../../data/models/quest_model.dart';

abstract interface class QuestRepository {
  Future<QuestModel?> getById(String id);
  Future<List<QuestModel>> getByProfileId(
    String profileId, {
    String? status,
  });
  Future<void> save(QuestModel quest);
  Future<void> delete(String id);
  Stream<List<QuestModel>> watchByProfileId(String profileId);
}
