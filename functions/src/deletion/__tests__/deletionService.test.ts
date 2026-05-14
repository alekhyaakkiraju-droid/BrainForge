jest.mock("firebase-admin", () => ({
  apps: [{}],
  initializeApp: jest.fn(),
  firestore: jest.fn(),
  auth: jest.fn(),
  storage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      deleteFiles: jest.fn().mockResolvedValue(undefined),
    })),
  })),
}));

jest.mock("firebase-admin/firestore", () => ({
  FieldValue: { serverTimestamp: jest.fn(() => "mock-ts") },
  getFirestore: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({
  getAuth: jest.fn(),
}));

import { deleteCollectionDocs, handleChildDataDeletion } from "../deletionService";
import type { Firestore } from "firebase-admin/firestore";
import type { Auth } from "firebase-admin/auth";

// ── Helpers ──────────────────────────────────────────────────────────────────

function makeDb(overrides: Partial<Record<string, jest.Mock>> = {}): Firestore {
  const docMock = {
    delete: jest.fn().mockResolvedValue(undefined),
    set: jest.fn().mockResolvedValue(undefined),
    update: jest.fn().mockResolvedValue(undefined),
    id: "mock-audit-id",
  };

  const batchMock = {
    delete: jest.fn(),
    commit: jest.fn().mockResolvedValue(undefined),
  };

  const base = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnValue(docMock),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({ empty: true, docs: [], size: 0 }),
    batch: jest.fn().mockReturnValue(batchMock),
    ...overrides,
  };

  return base as unknown as Firestore;
}

function makeAuth(overrides: Partial<Record<string, jest.Mock>> = {}): Auth {
  return {
    deleteUser: jest.fn().mockResolvedValue(undefined),
    ...overrides,
  } as unknown as Auth;
}

// ── deleteCollectionDocs ─────────────────────────────────────────────────────

describe("deleteCollectionDocs", () => {
  it("returns 0 when collection is empty", async () => {
    const db = makeDb();
    const count = await deleteCollectionDocs(db, "sessions", "userId", "u1");
    expect(count).toBe(0);
  });

  it("deletes documents in a single batch when < BATCH_SIZE", async () => {
    const docA = { ref: { id: "doc-a" } };
    const docB = { ref: { id: "doc-b" } };
    const batchMock = {
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };

    let callCount = 0;
    const db = makeDb({
      get: jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount === 1) {
          return Promise.resolve({ empty: false, docs: [docA, docB], size: 2 });
        }
        return Promise.resolve({ empty: true, docs: [], size: 0 });
      }),
      batch: jest.fn().mockReturnValue(batchMock),
    });

    const count = await deleteCollectionDocs(db, "sessions", "userId", "u1");
    expect(count).toBe(2);
    expect(batchMock.commit).toHaveBeenCalledTimes(1);
  });
});

// ── handleChildDataDeletion ──────────────────────────────────────────────────

describe("handleChildDataDeletion", () => {
  it("deletes Firebase Auth user", async () => {
    const db = makeDb();
    const auth = makeAuth();

    await handleChildDataDeletion("req-1", "parent-1", "child-1", db, auth);

    expect(auth.deleteUser).toHaveBeenCalledWith("child-1");
  });

  it("continues if Auth user does not exist (retry safety)", async () => {
    const db = makeDb();
    const auth = makeAuth({
      deleteUser: jest.fn().mockRejectedValue(new Error("user not found")),
    });

    await expect(
      handleChildDataDeletion("req-1", "parent-1", "child-1", db, auth)
    ).resolves.toBeDefined();
  });

  it("marks deletion_request as completed", async () => {
    const updateMock = jest.fn().mockResolvedValue(undefined);
    const docMock = {
      delete: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(undefined),
      update: updateMock,
      id: "audit-id",
    };

    const db = makeDb({ doc: jest.fn().mockReturnValue(docMock) });
    const auth = makeAuth();

    await handleChildDataDeletion("req-1", "parent-1", "child-1", db, auth);

    expect(updateMock).toHaveBeenCalledWith(
      expect.objectContaining({ status: "completed" })
    );
  });

  it("returns list of deleted collections including users", async () => {
    const db = makeDb();
    const auth = makeAuth();

    const result = await handleChildDataDeletion(
      "req-1",
      "parent-1",
      "child-1",
      db,
      auth
    );

    expect(result.collectionsDeleted).toContain("users");
  });
});
