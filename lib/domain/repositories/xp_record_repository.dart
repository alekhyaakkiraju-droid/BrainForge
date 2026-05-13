import '../../data/models/xp_record_model.dart';

abstract interface class XpRecordRepository {
  Future<XpRecordModel?> getById(String id);
  Future<List<XpRecordModel>> getByProfileId(String profileId);
  Future<void> save(XpRecordModel record);
  Future<void> delete(String id);
}
