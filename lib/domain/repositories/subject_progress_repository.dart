import '../../data/models/subject_progress_model.dart';

abstract interface class SubjectProgressRepository {
  Future<SubjectProgressModel?> getById(String id);
  Future<List<SubjectProgressModel>> getByProfileId(String profileId);
  Future<SubjectProgressModel?> getByProfileAndSubject(
    String profileId,
    String subject,
  );
  Future<void> save(SubjectProgressModel progress);
  Future<void> delete(String id);
  Stream<List<SubjectProgressModel>> watchByProfileId(String profileId);
}
