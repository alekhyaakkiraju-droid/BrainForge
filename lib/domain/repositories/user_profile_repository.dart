import '../../data/models/user_profile_model.dart';

abstract interface class UserProfileRepository {
  Future<UserProfileModel?> getById(String id);
  Future<List<UserProfileModel>> getByParentUid(String parentUid);
  Future<void> save(UserProfileModel profile);
  Future<void> delete(String id);
  Stream<UserProfileModel?> watch(String id);
}
