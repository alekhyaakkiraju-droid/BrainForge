import { extractIpAddress, handleRecordConsent } from "../consentService";

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

// ── helpers ─────────────────────────────────────────────────────────────────

function makeDb(consentExists: boolean) {
  const docSnap = { exists: consentExists };
  const transaction = {
    set: jest.fn(),
  };

  return {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue(docSnap),
      id: "audit-1",
    }),
    runTransaction: jest.fn().mockImplementation(
      async (fn: (tx: typeof transaction) => Promise<void>) => fn(transaction)
    ),
  } as unknown as import("firebase-admin/firestore").Firestore;
}

// ── extractIpAddress ─────────────────────────────────────────────────────────

describe("extractIpAddress", () => {
  it("returns first IP from x-forwarded-for string", () => {
    expect(
      extractIpAddress({ "x-forwarded-for": "1.2.3.4, 5.6.7.8" })
    ).toBe("1.2.3.4");
  });

  it("returns first IP from x-forwarded-for array", () => {
    expect(
      extractIpAddress({ "x-forwarded-for": ["9.9.9.9", "1.1.1.1"] })
    ).toBe("9.9.9.9");
  });

  it("returns 'unknown' when header is absent", () => {
    expect(extractIpAddress({})).toBe("unknown");
  });
});

// ── handleRecordConsent ──────────────────────────────────────────────────────

describe("handleRecordConsent", () => {
  it("throws failed-precondition when email is not verified", async () => {
    const db = makeDb(false);
    await expect(
      handleRecordConsent("uid-1", false, "1.2.3.4", db)
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("returns alreadyRecorded:true when consent doc exists", async () => {
    const db = makeDb(true);
    const result = await handleRecordConsent("uid-1", true, "1.2.3.4", db);
    expect(result).toEqual({ success: true, alreadyRecorded: true });
  });

  it("writes consent doc and audit log in a transaction", async () => {
    const db = makeDb(false);
    const result = await handleRecordConsent("uid-1", true, "10.0.0.1", db);
    expect(result).toEqual({ success: true, alreadyRecorded: false });
    expect(
      (db as unknown as { runTransaction: jest.Mock }).runTransaction
    ).toHaveBeenCalled();
  });

  it("does not throw HttpsError when all conditions are met", async () => {
    const db = makeDb(false);
    await expect(
      handleRecordConsent("uid-2", true, "127.0.0.1", db)
    ).resolves.not.toThrow();
  });
});
