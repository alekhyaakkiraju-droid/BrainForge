import '../../data/models/badge_model.dart';

abstract interface class BadgeRepository {
  Future<BadgeModel?> getById(String id);
  Future<List<BadgeModel>> getByProfileId(String profileId);
  Future<void> save(BadgeModel badge);
  Future<void> delete(String id);
}
