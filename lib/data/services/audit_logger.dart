import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides [AuditLogger] as a Riverpod singleton backed by the default
/// [FirebaseFirestore] instance.
final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => AuditLogger(FirebaseFirestore.instance),
);

/// Supported audit operation verbs.
///
/// Extend this list when new tracked operations are added — using an explicit
/// enum prevents free-form strings from slipping into the audit trail.
enum AuditOperation {
  create,
  update,
  delete,
  login,
  logout,
  consentRecorded,
  childAccountCreated,
  childDataDeleted,
}

/// Writes structured, immutable audit log entries to the `auditLogs` Firestore
/// collection.
///
/// Firestore security rules on `auditLogs/{logId}` allow **create only** —
/// update and delete are unconditionally denied for every role.  This makes
/// every entry a permanent record, satisfying COPPA audit requirements.
///
/// Prefer this class over direct Firestore writes to `auditLogs` so all
/// entries share a consistent schema.
class AuditLogger {
  const AuditLogger(this._firestore);

  final FirebaseFirestore _firestore;

  /// Appends an audit entry and returns the generated document ID.
  ///
  /// [actor] — UID of the authenticated user who triggered the action.
  /// [resource] — Firestore path of the primary document affected
  ///   (e.g. `"users/uid-123"`).
  /// [operation] — The kind of action performed.
  /// [details] — Optional free-form context (changed fields, IP address…).
  Future<String> log({
    required String actor,
    required String resource,
    required AuditOperation operation,
    Map<String, dynamic>? details,
  }) async {
    final ref = _firestore.collection('auditLogs').doc();
    await ref.set({
      'actor': actor,
      'timestamp': FieldValue.serverTimestamp(),
      'resource': resource,
      'operation': operation.name,
      'details': details ?? <String, dynamic>{},
    });
    return ref.id;
  }
}
