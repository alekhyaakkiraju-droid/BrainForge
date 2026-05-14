import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { Auth } from "firebase-admin/auth";
import { admin } from "../config/admin";

/** Collections whose documents are owned per-child and must be fully purged. */
const CHILD_COLLECTIONS: Array<{ name: string; field: string }> = [
  { name: "sessions", field: "userId" },
  { name: "xp_records", field: "userId" },
  { name: "mood_entries", field: "userId" },
  { name: "badges", field: "userId" },
  { name: "subject_progress", field: "userId" },
  { name: "quest_submissions", field: "userId" },
];

/** Maximum documents deleted per Firestore batch write. */
const BATCH_SIZE = 400;

/**
 * Deletes all documents in a collection where `field == childUid`.
 * Processes in batches to stay within Firestore write limits.
 *
 * Returns the number of documents deleted.
 */
export async function deleteCollectionDocs(
  db: Firestore,
  collectionName: string,
  fieldName: string,
  childUid: string
): Promise<number> {
  let totalDeleted = 0;

  // Loop until no documents remain — handles collections larger than BATCH_SIZE.
  for (;;) {
    const snapshot = await db
      .collection(collectionName)
      .where(fieldName, "==", childUid)
      .limit(BATCH_SIZE)
      .get();

    if (snapshot.empty) break;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snapshot.size;
  }

  return totalDeleted;
}

/**
 * Core deletion logic. Separated from the Firestore trigger wrapper so it can
 * be unit-tested without an event context.
 *
 * Execution order:
 *  1. Delete all child documents across every collection.
 *  2. Delete the Firebase Auth account for the child.
 *  3. Delete Cloud Storage files under users/{childUid}/.
 *  4. Delete the child profile document from users/.
 *  5. Write an immutable audit log.
 *  6. Mark the deletion request as completed.
 */
export async function handleChildDataDeletion(
  requestId: string,
  parentUid: string,
  childUid: string,
  db: Firestore,
  auth: Auth
): Promise<{ collectionsDeleted: string[] }> {
  const deletedCollections: string[] = [];

  // 1. Delete sub-collection documents.
  for (const { name, field } of CHILD_COLLECTIONS) {
    const count = await deleteCollectionDocs(db, name, field, childUid);
    if (count > 0) deletedCollections.push(name);
  }

  // 2. Delete Firebase Auth account for the child.
  try {
    await auth.deleteUser(childUid);
  } catch {
    // User may not exist if the request is a retry — log but continue.
  }

  // 3. Delete Cloud Storage files under users/{childUid}/.
  try {
    const bucket = admin.storage().bucket();
    await bucket.deleteFiles({ prefix: `users/${childUid}/` });
    deletedCollections.push("storage:users/" + childUid);
  } catch {
    // Storage may be empty or bucket not configured — non-fatal.
  }

  // 4. Delete the child profile document.
  await db.collection("users").doc(childUid).delete();
  deletedCollections.push("users");

  const now = FieldValue.serverTimestamp();

  // 5. Immutable audit entry.
  await db.collection("auditLogs").doc().set({
    actorUid: parentUid,
    action: "CHILD_DATA_DELETED",
    resourceType: "user",
    resourceId: childUid,
    timestamp: now,
    metadata: {
      requestId,
      collectionsDeleted: deletedCollections,
    },
  });

  // 6. Mark deletion request completed.
  await db.collection("deletion_requests").doc(requestId).update({
    status: "completed",
    completedAt: now,
    collectionsDeleted: deletedCollections,
  });

  return { collectionsDeleted: deletedCollections };
}

/**
 * Firestore-triggered Cloud Function that executes the data deletion pipeline
 * whenever a parent creates a document in `deletion_requests/`.
 *
 * The function runs immediately (COPPA requires deletion "as soon as
 * reasonably practicable" — we target ≤ 48 hours; immediate is better).
 * Retries are handled automatically by the Cloud Functions runtime.
 */
export const processDataDeletion = onDocumentCreated(
  "deletion_requests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { parentUid, childUid } = data as {
      parentUid: string;
      childUid: string;
    };

    if (!parentUid || !childUid) return;

    await handleChildDataDeletion(
      event.params.requestId,
      parentUid,
      childUid,
      admin.firestore(),
      admin.auth()
    );
  }
);
