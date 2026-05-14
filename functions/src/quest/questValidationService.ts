import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { admin } from "../config/admin";

// ── Types ──────────────────────────────────────────────────────────────────

export interface ValidationResult {
  correct: boolean;
  xpEarned: number;
  feedback: string;
}

interface QuestDoc {
  assignedToProfileId: string;
  xpReward: number;
  steps?: StepDoc[];
  status?: string;
}

interface StepDoc {
  correctAnswer?: string | null;
  type: string;
}

// ── Business logic (pure — testable without HTTP context) ─────────────────

/**
 * Validates a single quest step submission and awards XP for correct answers.
 *
 * Rejects if:
 * - The quest is not assigned to the requesting user.
 * - The step index is already recorded as completed (idempotency).
 * - The answer is incorrect.
 */
export async function handleValidateQuestSubmission(
  uid: string,
  questId: string,
  stepIndex: number,
  answer: string,
  db: Firestore
): Promise<ValidationResult> {
  const questRef = db.collection("quests").doc(questId);
  const questSnap = await questRef.get();

  if (!questSnap.exists) {
    throw new HttpsError("not-found", `Quest ${questId} not found.`);
  }

  const quest = questSnap.data() as QuestDoc;

  // Auth check — only the assigned student may submit.
  if (quest.assignedToProfileId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "This quest is not assigned to you."
    );
  }

  // Idempotency — check the questProgress document.
  const progressId = `${uid}_${questId}`;
  const progressSnap = await db
    .collection("questProgress")
    .doc(progressId)
    .get();

  const completedIndices: number[] =
    (progressSnap.data()?.completedStepIndices as number[]) ?? [];

  if (completedIndices.includes(stepIndex)) {
    // Already completed — return success without awarding XP again.
    return {
      correct: true,
      xpEarned: 0,
      feedback: "You already completed this step! Keep going! 🌟",
    };
  }

  // Validate the answer.
  const steps = quest.steps ?? [];
  const step: StepDoc | undefined = steps[stepIndex];

  const isCorrect = _checkAnswer(step, answer);

  if (!isCorrect) {
    await _writeAuditLog(db, uid, questId, stepIndex, false, 0);
    return {
      correct: false,
      xpEarned: 0,
      feedback: "Not quite — give it another try! You've got this! 💪",
    };
  }

  const xpEarned = quest.xpReward ?? 0;

  // Persist progress, XP record, and audit log in a batch.
  const batch = db.batch();

  batch.set(
    db.collection("questProgress").doc(progressId),
    {
      profileId: uid,
      questId,
      completedStepIndices: FieldValue.arrayUnion(stepIndex),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const xpRef = db.collection("xp_records").doc();
  batch.set(xpRef, {
    profileId: uid,
    questId,
    stepIndex,
    xpEarned,
    earnedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  await _writeAuditLog(db, uid, questId, stepIndex, true, xpEarned);

  return {
    correct: true,
    xpEarned,
    feedback: "Correct! Amazing work! ⭐",
  };
}

// ── Helpers ────────────────────────────────────────────────────────────────

function _checkAnswer(step: StepDoc | undefined, answer: string): boolean {
  if (!step || step.correctAnswer == null) {
    // Interaction steps or steps without a correct answer are always correct.
    return true;
  }
  return (
    step.correctAnswer.trim().toLowerCase() === answer.trim().toLowerCase()
  );
}

async function _writeAuditLog(
  db: Firestore,
  uid: string,
  questId: string,
  stepIndex: number,
  correct: boolean,
  xpEarned: number
): Promise<void> {
  await db.collection("auditLogs").add({
    actor: uid,
    timestamp: FieldValue.serverTimestamp(),
    resource: `quests/${questId}/steps/${stepIndex}`,
    operation: "quest_submission",
    details: { correct, xpEarned },
  });
}

// ── Callable export ────────────────────────────────────────────────────────

export const validateQuestSubmission = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { questId, stepIndex, answer } = request.data as {
      questId: string;
      stepIndex: number;
      answer: string;
    };

    if (!questId || stepIndex == null || answer == null) {
      throw new HttpsError(
        "invalid-argument",
        "questId, stepIndex, and answer are required."
      );
    }

    const db = admin.firestore();
    return handleValidateQuestSubmission(uid, questId, stepIndex, answer, db);
  }
);
