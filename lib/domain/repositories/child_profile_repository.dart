import '../../core/utils/result.dart';
import '../entities/child_profile.dart';

/// Pure Dart interface — no Firebase or Hive imports.
///
/// Keeping the repository interface free of vendor SDKs means the data
/// layer can switch between Firebase and AWS (or mock in tests) without
/// touching the domain or presentation layers.
abstract interface class ChildProfileRepository {
  Future<Result<ChildProfile>> getProfile(String profileId);
  Future<Result<List<ChildProfile>>> listProfiles(String parentAccountId);
  Future<Result<ChildProfile>> saveProfile(ChildProfile profile);
  Future<Result<void>> deleteProfile(String profileId);
  Future<Result<ChildProfile>> switchMode(
    String profileId,
    AppMode newMode,
  );
}
