import { handleValidateQuestSubmission } from "../questValidationService";
import { HttpsError } from "firebase-functions/v2/https";

// ── Firestore mock ─────────────────────────────────────────────────────────

function mockBatch() {
  const ops: unknown[] = [];
  return {
    set: jest.fn(() => ops),
    commit: jest.fn().mockResolvedValue(undefined),
  };
}

function makeDb({
  questData = null as unknown | null,
  progressData = null as unknown | null,
}: {
  questData?: unknown | null;
  progressData?: unknown | null;
} = {}) {
  const questSnap = { exists: questData !== null, data: () => questData };
  const progressSnap = {
    exists: progressData !== null,
    data: () => progressData,
  };
  const batch = mockBatch();

  const auditLogsCol = { add: jest.fn().mockResolvedValue({ id: "audit-id" }) };
  const xpRecordsCol = { doc: jest.fn(() => ({ id: "xp-id" })) };

  const collection = jest.fn((name: string) => {
    if (name === "auditLogs") return auditLogsCol;
    if (name === "xp_records") return xpRecordsCol;
    // quests / questProgress
    return {
      doc: jest.fn((_?: string) => ({
        get: jest.fn().mockResolvedValue(
          name === "quests" ? questSnap : progressSnap
        ),
        set: jest.fn().mockResolvedValue(undefined),
      })),
    };
  });

  return {
    collection,
    batch: jest.fn(() => batch),
    _batch: batch,
    _auditLogs: auditLogsCol,
  };
}

const BASE_QUEST = {
  assignedToProfileId: "student-1",
  xpReward: 25,
  status: "active",
  steps: [
    { type: "multiple_choice", correctAnswer: "Paris" },
    { type: "text_input", correctAnswer: "42" },
    { type: "interaction", correctAnswer: null },
  ],
};

describe("handleValidateQuestSubmission", () => {
  it("throws not-found when quest does not exist", async () => {
    const db = makeDb({ questData: null });
    await expect(
      handleValidateQuestSubmission(
        "student-1",
        "quest-99",
        0,
        "Paris",
        db as never
      )
    ).rejects.toThrow(HttpsError);
  });

  it("throws permission-denied when quest belongs to another user", async () => {
    const db = makeDb({
      questData: { ...BASE_QUEST, assignedToProfileId: "other-student" },
    });
    await expect(
      handleValidateQuestSubmission(
        "student-1",
        "quest-1",
        0,
        "Paris",
        db as never
      )
    ).rejects.toThrow(HttpsError);
  });

  it("returns already-completed result for duplicate submission", async () => {
    const db = makeDb({
      questData: BASE_QUEST,
      progressData: { completedStepIndices: [0] },
    });
    const result = await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "Paris",
      db as never
    );
    expect(result.correct).toBe(true);
    expect(result.xpEarned).toBe(0);
  });

  it("returns correct=false for wrong answer", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    const result = await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "London",
      db as never
    );
    expect(result.correct).toBe(false);
    expect(result.xpEarned).toBe(0);
  });

  it("returns correct=true and xpEarned for correct answer", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    const result = await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "Paris",
      db as never
    );
    expect(result.correct).toBe(true);
    expect(result.xpEarned).toBe(25);
  });

  it("is case-insensitive for answer comparison", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    const result = await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "PARIS",
      db as never
    );
    expect(result.correct).toBe(true);
  });

  it("accepts any answer for interaction-type steps", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    const result = await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      2,
      "done",
      db as never
    );
    expect(result.correct).toBe(true);
  });

  it("writes XP record and updates progress on correct answer", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "Paris",
      db as never
    );
    expect(db._batch.set).toHaveBeenCalled();
    expect(db._batch.commit).toHaveBeenCalled();
  });

  it("writes audit log for a correct submission", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "Paris",
      db as never
    );
    expect(db._auditLogs.add).toHaveBeenCalled();
  });

  it("writes audit log for an incorrect submission", async () => {
    const db = makeDb({ questData: BASE_QUEST });
    await handleValidateQuestSubmission(
      "student-1",
      "quest-1",
      0,
      "London",
      db as never
    );
    expect(db._auditLogs.add).toHaveBeenCalled();
  });

  it("validateQuestSubmission is a callable function export", async () => {
    const { validateQuestSubmission } = await import(
      "../questValidationService"
    );
    expect(typeof validateQuestSubmission).toBe("function");
  });
});
