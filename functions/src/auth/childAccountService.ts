import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { Auth } from "firebase-admin/auth";
import { admin } from "../config/admin";
import { hashPin } from "../utils/hashPin";
import {
  isValidUsername,
  isValidPin,
  isAllowedAgeRange,
  isAllowedAvatarId,
  ALLOWED_AGE_RANGES,
} from "../utils/validation";

interface CreateChildInput {
  username: string;
  ageRange: string;
  avatarId: string;
  pin: string;
}

interface ChildSignInInput {
  username: string;
  pin: string;
}

export async function handleCreateChildAccount(
  parentUid: string,
  emailVerified: boolean,
  input: CreateChildInput,
  db: Firestore,
  auth: Auth
): Promise<{ childUid: string; customToken: string }> {
  if (!emailVerified) {
    throw new HttpsError("permission-denied", "CONSENT_REQUIRED");
  }

  const consentDoc = await db.collection("consents").doc(parentUid).get();
  if (!consentDoc.exists) {
    throw new HttpsError("permission-denied", "CONSENT_REQUIRED");
  }

  const { username, ageRange, avatarId, pin } = input;

  if (!isValidUsername(username)) {
    throw new HttpsError(
      "invalid-argument",
      "Username must be 3–20 alphanumeric characters or underscores."
    );
  }
  if (!isAllowedAgeRange(ageRange)) {
    throw new HttpsError(
      "invalid-argument",
      `Age range must be one of: ${ALLOWED_AGE_RANGES.join(", ")}.`
    );
  }
  if (!isAllowedAvatarId(avatarId)) {
    throw new HttpsError("invalid-argument", "Invalid avatar selection.");
  }
  if (!isValidPin(pin)) {
    throw new HttpsError("invalid-argument", "PIN must be exactly 4 digits.");
  }

  const usernameQuery = await db
    .collection("users")
    .where("username", "==", username)
    .limit(1)
    .get();
  if (!usernameQuery.empty) {
    throw new HttpsError("already-exists", "Username is already taken.");
  }

  // Internal email — children never see or type this address.
  const internalEmail = `child_${Date.now()}_${parentUid}@brainforge.internal`;
  const tempPassword = hashPin(`${parentUid}${Date.now()}`).slice(0, 16);

  const childUser = await auth.createUser({
    email: internalEmail,
    password: tempPassword,
    displayName: username,
  });

  await auth.setCustomUserClaims(childUser.uid, {
    role: "student",
    parentId: parentUid,
  });

  const now = FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    tx.set(db.collection("users").doc(childUser.uid), {
      uid: childUser.uid,
      username,
      ageRange,
      avatarId,
      parentId: parentUid,
      role: "student",
      pinHash: hashPin(pin),
      xp: 0,
      level: 1,
      createdAt: now,
      updatedAt: now,
    });

    const auditRef = db.collection("auditLogs").doc();
    tx.set(auditRef, {
      id: auditRef.id,
      actorUid: parentUid,
      action: "CHILD_ACCOUNT_CREATED",
      resourceType: "user",
      resourceId: childUser.uid,
      timestamp: now,
      metadata: { username, ageRange, avatarId },
    });
  });

  const customToken = await auth.createCustomToken(childUser.uid, {
    role: "student",
    parentId: parentUid,
  });

  return { childUid: childUser.uid, customToken };
}

export async function handleChildSignIn(
  input: ChildSignInInput,
  db: Firestore,
  auth: Auth
): Promise<{ customToken: string }> {
  const { username, pin } = input;

  if (!username || !pin) {
    throw new HttpsError("invalid-argument", "Username and PIN are required.");
  }

  const query = await db
    .collection("users")
    .where("username", "==", username)
    .where("role", "==", "student")
    .limit(1)
    .get();

  if (query.empty) {
    throw new HttpsError("not-found", "Child account not found.");
  }

  const childData = query.docs[0].data();

  if (childData["pinHash"] !== hashPin(pin)) {
    throw new HttpsError("permission-denied", "Incorrect PIN.");
  }

  const customToken = await auth.createCustomToken(query.docs[0].id, {
    role: "student",
    parentId: childData["parentId"] as string,
  });

  return { customToken };
}

export const createChildAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  return handleCreateChildAccount(
    request.auth.uid,
    Boolean(request.auth.token.email_verified),
    request.data as CreateChildInput,
    admin.firestore(),
    admin.auth()
  );
});

export const childSignIn = onCall(async (request) => {
  return handleChildSignIn(
    request.data as ChildSignInInput,
    admin.firestore(),
    admin.auth()
  );
});
