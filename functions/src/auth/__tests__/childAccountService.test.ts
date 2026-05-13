import { handleCreateChildAccount, handleChildSignIn } from "../childAccountService";
import { hashPin } from "../../utils/hashPin";

jest.mock("firebase-admin", () => ({
  apps: [true],
  initializeApp: jest.fn(),
}));
jest.mock("firebase-functions/v2/https", () => ({
  onCall: (h: unknown) => h,
  HttpsError: class extends Error {
    constructor(
      public readonly code: string,
      message: string
    ) {
      super(message);
      this.name = "HttpsError";
    }
  },
}));

// ── helpers ──────────────────────────────────────────────────────────────────

const VALID_INPUT = {
  username: "kiddo_1",
  ageRange: "8-10",
  avatarId: "avatar_1",
  pin: "1234",
};

function makeDb({
  consentExists,
  usernameExists,
  childUid = "child-uid",
  storedPinHash,
  parentId = "parent-uid",
}: {
  consentExists: boolean;
  usernameExists: boolean;
  childUid?: string;
  storedPinHash?: string;
  parentId?: string;
}) {
  const transaction = { set: jest.fn() };

  const consentSnap = { exists: consentExists };
  const usernameSnap = {
    empty: !usernameExists,
    docs: usernameExists ? [{ id: "existing" }] : [],
  };

  const childSnap = {
    empty: !storedPinHash,
    docs: storedPinHash
      ? [{ id: childUid, data: () => ({ pinHash: storedPinHash, parentId }) }]
      : [],
  };

  return {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue(consentSnap),
      id: "audit-ref",
    }),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn()
      .mockResolvedValueOnce(usernameSnap) // username uniqueness check
      .mockResolvedValueOnce(childSnap),   // childSignIn lookup
    runTransaction: jest.fn().mockImplementation(
      async (fn: (tx: typeof transaction) => Promise<void>) => fn(transaction)
    ),
  } as unknown as import("firebase-admin/firestore").Firestore;
}

function makeAuth(childUid = "child-uid") {
  return {
    createUser: jest.fn().mockResolvedValue({ uid: childUid }),
    setCustomUserClaims: jest.fn().mockResolvedValue(undefined),
    createCustomToken: jest.fn().mockResolvedValue("mock-token"),
  } as unknown as import("firebase-admin/auth").Auth;
}

// ── handleCreateChildAccount ─────────────────────────────────────────────────

describe("handleCreateChildAccount", () => {
  it("throws permission-denied (CONSENT_REQUIRED) when email unverified", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", false, VALID_INPUT, db, makeAuth())
    ).rejects.toMatchObject({ code: "permission-denied", message: "CONSENT_REQUIRED" });
  });

  it("throws permission-denied (CONSENT_REQUIRED) when no consent doc", async () => {
    const db = makeDb({ consentExists: false, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", true, VALID_INPUT, db, makeAuth())
    ).rejects.toMatchObject({ code: "permission-denied", message: "CONSENT_REQUIRED" });
  });

  it("throws invalid-argument for bad username", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", true, { ...VALID_INPUT, username: "x" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws invalid-argument for bad age range", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", true, { ...VALID_INPUT, ageRange: "99-99" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws invalid-argument for bad avatar", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", true, { ...VALID_INPUT, avatarId: "bad" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws invalid-argument for non-4-digit PIN", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleCreateChildAccount("p1", true, { ...VALID_INPUT, pin: "12" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws already-exists when username is taken", async () => {
    const db = makeDb({ consentExists: true, usernameExists: true });
    await expect(
      handleCreateChildAccount("p1", true, VALID_INPUT, db, makeAuth())
    ).rejects.toMatchObject({ code: "already-exists" });
  });

  it("returns childUid and customToken on success", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    const auth = makeAuth("child-123");
    const result = await handleCreateChildAccount("p1", true, VALID_INPUT, db, auth);
    expect(result.childUid).toBe("child-123");
    expect(result.customToken).toBe("mock-token");
  });

  it("sets custom claims with role:student and parentId", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    const auth = makeAuth();
    await handleCreateChildAccount("parent-uid", true, VALID_INPUT, db, auth);
    expect(auth.setCustomUserClaims).toHaveBeenCalledWith(
      expect.any(String),
      { role: "student", parentId: "parent-uid" }
    );
  });
});

// ── handleChildSignIn ─────────────────────────────────────────────────────────

describe("handleChildSignIn", () => {
  it("throws invalid-argument when username is missing", async () => {
    const db = makeDb({ consentExists: true, usernameExists: false });
    await expect(
      handleChildSignIn({ username: "", pin: "1234" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws not-found when username does not exist", async () => {
    // First db.get() call in handleChildSignIn — returns empty
    const db = {
      collection: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
    } as unknown as import("firebase-admin/firestore").Firestore;
    await expect(
      handleChildSignIn({ username: "nobody", pin: "1234" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "not-found" });
  });

  it("throws permission-denied for wrong PIN", async () => {
    const db = {
      collection: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({
        empty: false,
        docs: [{ id: "c1", data: () => ({ pinHash: hashPin("9999"), parentId: "p1" }) }],
      }),
    } as unknown as import("firebase-admin/firestore").Firestore;
    await expect(
      handleChildSignIn({ username: "kid", pin: "1234" }, db, makeAuth())
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("returns customToken on correct PIN", async () => {
    const correctPin = "5678";
    const db = {
      collection: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({
        empty: false,
        docs: [{
          id: "c1",
          data: () => ({ pinHash: hashPin(correctPin), parentId: "p1" }),
        }],
      }),
    } as unknown as import("firebase-admin/firestore").Firestore;
    const result = await handleChildSignIn({ username: "kid", pin: correctPin }, db, makeAuth());
    expect(result.customToken).toBe("mock-token");
  });
});
