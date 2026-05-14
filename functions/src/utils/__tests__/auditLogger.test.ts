jest.mock("firebase-admin", () => ({
  apps: [{}],
  initializeApp: jest.fn(),
  firestore: jest.fn(),
}));

jest.mock("firebase-admin/firestore", () => ({
  FieldValue: { serverTimestamp: jest.fn(() => "mock-ts") },
  getFirestore: jest.fn(),
}));

jest.mock("firebase-admin/auth", () => ({ getAuth: jest.fn() }));

import { writeAuditLog } from "../auditLogger";
import type { Firestore } from "firebase-admin/firestore";

function makeDb(setMock: jest.Mock): Firestore {
  return {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnValue({ set: setMock, id: "generated-id" }),
  } as unknown as Firestore;
}

describe("writeAuditLog", () => {
  it("calls db.collection(auditLogs).doc().set with merged entry", async () => {
    const setMock = jest.fn().mockResolvedValue(undefined);
    const db = makeDb(setMock);

    await writeAuditLog(db, {
      actor: "user-1",
      resource: "users/user-1",
      operation: "login",
      details: { ip: "1.2.3.4" },
    });

    expect(setMock).toHaveBeenCalledWith(
      expect.objectContaining({
        actor: "user-1",
        resource: "users/user-1",
        operation: "login",
        details: { ip: "1.2.3.4" },
        timestamp: "mock-ts",
      })
    );
  });

  it("returns the generated document ID", async () => {
    const setMock = jest.fn().mockResolvedValue(undefined);
    const db = makeDb(setMock);

    const id = await writeAuditLog(db, {
      actor: "user-1",
      resource: "users/user-1",
      operation: "create",
      details: {},
    });

    expect(id).toBe("generated-id");
  });

  it("accepts an empty details object", async () => {
    const setMock = jest.fn().mockResolvedValue(undefined);
    const db = makeDb(setMock);

    await expect(
      writeAuditLog(db, {
        actor: "user-1",
        resource: "users/user-1",
        operation: "delete",
        details: {},
      })
    ).resolves.toBeDefined();
  });

  it("propagates Firestore write errors", async () => {
    const setMock = jest.fn().mockRejectedValue(new Error("firestore error"));
    const db = makeDb(setMock);

    await expect(
      writeAuditLog(db, {
        actor: "user-1",
        resource: "users/user-1",
        operation: "update",
        details: {},
      })
    ).rejects.toThrow("firestore error");
  });
});
