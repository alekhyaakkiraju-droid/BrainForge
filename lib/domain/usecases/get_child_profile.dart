import '../../core/utils/result.dart';
import '../entities/child_profile.dart';
import '../repositories/child_profile_repository.dart';

/// Fetches a child profile by ID.
///
/// Use-cases are thin orchestrators — they hold business rules that don't
/// belong in a repository (e.g. COPPA field exclusion) or a widget.
class GetChildProfile {
  const GetChildProfile(this._repository);

  final ChildProfileRepository _repository;

  Future<Result<ChildProfile>> call(String profileId) =>
      _repository.getProfile(profileId);
}
