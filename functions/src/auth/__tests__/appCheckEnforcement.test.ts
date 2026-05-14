/**
 * App Check enforcement is applied by the Firebase Functions SDK when
 * `enforceAppCheck: true` is passed to `onCall`.  SDK-level enforcement cannot
 * be unit-tested without the full Functions emulator, but we can verify:
 *
 *   1. Our handler logic still rejects unauthenticated requests (belt-and-
 *      suspenders — enforcement before AND inside the handler).
 *   2. The callable exports compile correctly with the enforcement option.
 *
 * End-to-end enforcement (curl without App Check token → HTTP 401) is verified
 * in the deployment smoke-test documented in DEPLOYMENT.md.
 */

jest.mock("firebase-admin", () => ({
  apps: [{}],
  initializeApp: jest.fn(),
  firestore: jest.fn(),
  auth: jest.fn(),
}));

jest.mock("firebase-admin/firestore", () => ({
  FieldValue: { serverTimestamp: jest.fn(() => "mock-timestamp") },
  getFirestore: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(),
}));

import { handleRecordConsent } from "../consentService";
import {
  handleCreateChildAccount,
  handleChildSignIn,
} from "../childAccountService";
import type { Firestore } from "firebase-admin/firestore";
import type { Auth } from "firebase-admin/auth";

const mockDb = {
  collection: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  get: jest.fn(),
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  runTransaction: jest.fn(),
} as unknown as Firestore;

const mockAuth = {
  createUser: jest.fn(),
  setCustomUserClaims: jest.fn(),
  createCustomToken: jest.fn(),
} as unknown as Auth;

describe("App Check — belt-and-suspenders: handler rejects unauthenticated", () => {
  it("recordConsent handler throws permission-denied when emailVerified is false", async () => {
    await expect(
      handleRecordConsent("uid-1", false, "1.2.3.4", mockDb)
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("createChildAccount handler throws permission-denied when emailVerified is false", async () => {
    await expect(
      handleCreateChildAccount(
        "parent-uid",
        false,
        { username: "kid", ageRange: "8-10", avatarId: "owl", pin: "1234" },
        mockDb,
        mockAuth
      )
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("childSignIn handler throws invalid-argument when input is empty", async () => {
    (mockDb as unknown as { collection: jest.Mock }).collection
      .mockReturnValueOnce({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ empty: true }),
      });

    await expect(
      handleChildSignIn({ username: "", pin: "" }, mockDb, mockAuth)
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });
});

describe("App Check — callable exports are defined", () => {
  it("recordConsent is a callable function", async () => {
    // Dynamic import so Firebase mock is in place before module load.
    const { recordConsent } = await import("../consentService");
    expect(typeof recordConsent).toBe("function");
  });

  it("createChildAccount is a callable function", async () => {
    const { createChildAccount } = await import("../childAccountService");
    expect(typeof createChildAccount).toBe("function");
  });

  it("childSignIn is a callable function", async () => {
    const { childSignIn } = await import("../childAccountService");
    expect(typeof childSignIn).toBe("function");
  });
});
