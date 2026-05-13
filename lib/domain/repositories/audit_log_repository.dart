import '../../data/models/audit_log_model.dart';

abstract interface class AuditLogRepository {
  Future<void> log(AuditLogModel entry);
  Future<List<AuditLogModel>> getByResourceId(String resourceId);
  Future<List<AuditLogModel>> getByActorUid(
    String actorUid, {
    int limit = 100,
  });
}
