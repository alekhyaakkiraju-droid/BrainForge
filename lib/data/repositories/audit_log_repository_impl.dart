import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/audit_log_repository.dart';
import '../models/audit_log_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'auditLogs';

class FirestoreAuditLogRepository implements AuditLogRepository {
  FirestoreAuditLogRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> log(AuditLogModel entry) => _db
      .collection(_kCollection)
      .doc(entry.id)
      .set(entry.toJson());

  @override
  Future<List<AuditLogModel>> getByResourceId(String resourceId) async {
    final snap = await _db
        .collection(_kCollection)
        .where('resourceId', isEqualTo: resourceId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => AuditLogModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<List<AuditLogModel>> getByActorUid(
    String actorUid, {
    int limit = 100,
  }) async {
    final snap = await _db
        .collection(_kCollection)
        .where('actorUid', isEqualTo: actorUid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => AuditLogModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return FirestoreAuditLogRepository(ref.watch(firestoreProvider));
});
