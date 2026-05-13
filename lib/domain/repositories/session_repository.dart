import '../../data/models/session_model.dart';

abstract interface class SessionRepository {
  Future<SessionModel?> getById(String id);
  Future<List<SessionModel>> getByProfileId(String profileId);
  Future<void> save(SessionModel session);
  Future<void> delete(String id);
  Stream<List<SessionModel>> watchByProfileId(String profileId);
}
