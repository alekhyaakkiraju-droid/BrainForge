import { FieldValue, Firestore } from "firebase-admin/firestore";

/** Immutable audit log entry shape written to `auditLogs/{autoId}`. */
export interface AuditEntry {
  /** UID of the authenticated user who performed the action. */
  actor: string;
  /** Server-assigned timestamp (always use FieldValue.serverTimestamp). */
  timestamp: ReturnType<typeof FieldValue.serverTimestamp>;
  /** Firestore path of the primary resource affected, e.g. "users/uid-123". */
  resource: string;
  /** Verb describing the mutation: create | update | delete | login | logout. */
  operation: string;
  /** Operation-specific key/value context (IPs, versions, affected fields…). */
  details: Record<string, unknown>;
}

/**
 * Writes a structured, immutable audit log entry to the `auditLogs` collection.
 *
 * The Firestore security rules on `auditLogs/{logId}` permit **create only** —
 * update and delete are unconditionally denied for every role.  This means once
 * written, no client or function can alter the record, satisfying the COPPA
 * audit-trail requirement.
 *
 * Call this helper instead of writing directly to `auditLogs` so all entries
 * share a consistent schema and future schema migrations only need updating here.
 */
export async function writeAuditLog(
  db: Firestore,
  entry: Omit<AuditEntry, "timestamp">
): Promise<string> {
  const ref = db.collection("auditLogs").doc();
  await ref.set({
    ...entry,
    timestamp: FieldValue.serverTimestamp(),
  });
  return ref.id;
}
