import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { admin } from "../config/admin";

const CONSENT_VERSION = "1.0.0";

/** Extracts the client's best-effort IP from common proxy headers. */
export function extractIpAddress(headers: Record<string, string | string[] | undefined>): string {
  const forwarded = headers["x-forwarded-for"];
  if (typeof forwarded === "string") return forwarded.split(",")[0].trim();
  if (Array.isArray(forwarded)) return forwarded[0];
  return "unknown";
}

/**
 * Core business logic — separated from the callable wrapper so it can be
 * unit-tested without an HTTP context.
 */
export async function handleRecordConsent(
  uid: string,
  emailVerified: boolean,
  ipAddress: string,
  db: Firestore
): Promise<{ success: boolean; alreadyRecorded: boolean }> {
  if (!emailVerified) {
    throw new HttpsError(
      "failed-precondition",
      "Email must be verified before recording consent."
    );
  }

  const consentRef = db.collection("consents").doc(uid);
  const existing = await consentRef.get();

  // Idempotent — return success if consent was already recorded.
  if (existing.exists) {
    return { success: true, alreadyRecorded: true };
  }

  const now = FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    // Consent document is immutable once written (enforced by Firestore rules).
    tx.set(consentRef, {
      parentUid: uid,
      timestamp: now,
      ipAddress,
      consentVersion: CONSENT_VERSION,
      recordedAt: now,
    });

    const auditRef = db.collection("auditLogs").doc();
    tx.set(auditRef, {
      id: auditRef.id,
      actorUid: uid,
      action: "CONSENT_RECORDED",
      resourceType: "consent",
      resourceId: uid,
      timestamp: now,
      metadata: { consentVersion: CONSENT_VERSION, ipAddress },
    });
  });

  return { success: true, alreadyRecorded: false };
}

// enforceAppCheck rejects requests missing a valid App Check token with HTTP
// 401 before the handler runs — protecting child data from API abuse.
export const recordConsent = onCall({ enforceAppCheck: true }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const ipAddress = extractIpAddress(
    request.rawRequest.headers as Record<string, string | string[] | undefined>
  );

  return handleRecordConsent(
    request.auth.uid,
    Boolean(request.auth.token.email_verified),
    ipAddress,
    admin.firestore()
  );
});
