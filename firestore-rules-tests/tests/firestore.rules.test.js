/**
 * Firestore security rules tests for BrainForge.
 *
 * Run against the Firebase emulator:
 *   firebase emulators:exec --only firestore 'npm test'
 *
 * Or start the emulator separately and run:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm test
 */

const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

// ── Fixture UIDs ─────────────────────────────────────────────────────────────

const STUDENT_UID = 'student-alice';
const PARENT_UID = 'parent-bob';
const OTHER_STUDENT_UID = 'student-charlie';
const TEACHER_UID = 'teacher-diana';

// ── Test environment ─────────────────────────────────────────────────────────

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'brainforge-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function studentCtx() {
  return testEnv.authenticatedContext(STUDENT_UID, { role: 'student' });
}

function parentCtx() {
  return testEnv.authenticatedContext(PARENT_UID, { role: 'parent' });
}

function otherStudentCtx() {
  return testEnv.authenticatedContext(OTHER_STUDENT_UID, { role: 'student' });
}

function teacherCtx() {
  return testEnv.authenticatedContext(TEACHER_UID, { role: 'teacher' });
}

function unauthCtx() {
  return testEnv.unauthenticatedContext();
}

async function seedUserDoc(uid, extra = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection('users').doc(uid).set({
      displayName: 'Alice',
      parentUid: PARENT_UID,
      parentId: PARENT_UID,
      mode: 'school',
      xp: 0,
      level: 1,
      ...extra,
    });
  });
}

// ── Users collection ─────────────────────────────────────────────────────────

describe('users/{userId}', () => {
  it('TEST-001: student can read own profile', async () => {
    await seedUserDoc(STUDENT_UID);
    await assertSucceeds(
      studentCtx().firestore().collection('users').doc(STUDENT_UID).get()
    );
  });

  it('TEST-002: student cannot read another student profile', async () => {
    await seedUserDoc(OTHER_STUDENT_UID);
    await assertFails(
      studentCtx().firestore().collection('users').doc(OTHER_STUDENT_UID).get()
    );
  });

  it('TEST-003: linked parent can read child profile', async () => {
    await seedUserDoc(STUDENT_UID, { parentId: PARENT_UID });
    await assertSucceeds(
      parentCtx().firestore().collection('users').doc(STUDENT_UID).get()
    );
  });

  it('TEST-004: parent cannot write to child profile', async () => {
    await seedUserDoc(STUDENT_UID, { parentId: PARENT_UID });
    await assertFails(
      parentCtx()
        .firestore()
        .collection('users')
        .doc(STUDENT_UID)
        .update({ xp: 9999 })
    );
  });

  it('TEST-005: teacher cannot read student profiles', async () => {
    await seedUserDoc(STUDENT_UID);
    await assertFails(
      teacherCtx().firestore().collection('users').doc(STUDENT_UID).get()
    );
  });

  it('TEST-006: unauthenticated user is denied', async () => {
    await seedUserDoc(STUDENT_UID);
    await assertFails(
      unauthCtx().firestore().collection('users').doc(STUDENT_UID).get()
    );
  });

  it('TEST-007: student can create own profile with valid data', async () => {
    await assertSucceeds(
      studentCtx()
        .firestore()
        .collection('users')
        .doc(STUDENT_UID)
        .set({
          displayName: 'Alice',
          parentUid: PARENT_UID,
          parentId: PARENT_UID,
          mode: 'school',
          xp: 0,
          level: 1,
        })
    );
  });

  it('TEST-008: student create is rejected when required field is missing', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('users')
        .doc(STUDENT_UID)
        .set({ displayName: 'Alice' }) // missing parentUid, mode, xp, level
    );
  });
});

// ── Quest submissions ────────────────────────────────────────────────────────

describe('questSubmissions/{submissionId}', () => {
  async function seedSubmission(id, profileId) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection('questSubmissions')
        .doc(id)
        .set({
          questId: 'q1',
          profileId,
          submittedAt: new Date().toISOString(),
          durationSeconds: 300,
          xpEarned: 50,
        });
    });
  }

  it('TEST-009: student can create own submission with valid data', async () => {
    await assertSucceeds(
      studentCtx()
        .firestore()
        .collection('questSubmissions')
        .add({
          questId: 'q1',
          profileId: STUDENT_UID,
          submittedAt: new Date().toISOString(),
          durationSeconds: 300,
          xpEarned: 50,
        })
    );
  });

  it('TEST-010: student submission rejected if questId missing', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('questSubmissions')
        .add({
          profileId: STUDENT_UID,
          submittedAt: new Date().toISOString(),
          durationSeconds: 300,
          xpEarned: 50,
          // no questId
        })
    );
  });

  it('TEST-011: student cannot create submission for another student', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('questSubmissions')
        .add({
          questId: 'q1',
          profileId: OTHER_STUDENT_UID, // different profile
          submittedAt: new Date().toISOString(),
          durationSeconds: 300,
          xpEarned: 50,
        })
    );
  });

  it('TEST-012: linked parent can read submission', async () => {
    await seedUserDoc(STUDENT_UID, { parentId: PARENT_UID });
    await seedSubmission('sub1', STUDENT_UID);
    await assertSucceeds(
      parentCtx()
        .firestore()
        .collection('questSubmissions')
        .doc('sub1')
        .get()
    );
  });
});

// ── Mood entries ─────────────────────────────────────────────────────────────

describe('moodEntries/{entryId}', () => {
  it('TEST-013: student can create mood entry with valid mood', async () => {
    await assertSucceeds(
      studentCtx()
        .firestore()
        .collection('moodEntries')
        .add({
          profileId: STUDENT_UID,
          mood: 'happy',
          intensity: 4,
          recordedAt: new Date().toISOString(),
        })
    );
  });

  it('TEST-014: mood entry rejected for invalid mood value', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('moodEntries')
        .add({
          profileId: STUDENT_UID,
          mood: 'angry', // not in allowed list
          intensity: 3,
          recordedAt: new Date().toISOString(),
        })
    );
  });

  it('TEST-015: mood entry rejected for intensity out of range', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('moodEntries')
        .add({
          profileId: STUDENT_UID,
          mood: 'okay',
          intensity: 6, // > 5
          recordedAt: new Date().toISOString(),
        })
    );
  });
});

// ── XP records (admin-only write) ────────────────────────────────────────────

describe('xpRecords/{recordId}', () => {
  async function seedXpRecord(id, profileId) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('xpRecords').doc(id).set({
        profileId,
        amount: 50,
        source: 'quest',
        description: 'Completed quest',
        earnedAt: new Date().toISOString(),
      });
    });
  }

  it('TEST-016: student cannot write XP records (Cloud Function only)', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('xpRecords')
        .add({
          profileId: STUDENT_UID,
          amount: 9999,
          source: 'cheat',
          description: 'Hacked',
          earnedAt: new Date().toISOString(),
        })
    );
  });

  it('TEST-017: student can read own XP records', async () => {
    await seedXpRecord('xp1', STUDENT_UID);
    await assertSucceeds(
      studentCtx().firestore().collection('xpRecords').doc('xp1').get()
    );
  });
});

// ── Class aggregates (teacher read) ──────────────────────────────────────────

describe('classAggregates/{classId}', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection('classAggregates')
        .doc('class-5a')
        .set({ averageXp: 400, questCompletionRate: 0.82 });
    });
  });

  it('TEST-018: teacher can read class aggregates', async () => {
    await assertSucceeds(
      teacherCtx()
        .firestore()
        .collection('classAggregates')
        .doc('class-5a')
        .get()
    );
  });

  it('TEST-019: student cannot read class aggregates', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('classAggregates')
        .doc('class-5a')
        .get()
    );
  });

  it('TEST-020: teacher cannot write class aggregates', async () => {
    await assertFails(
      teacherCtx()
        .firestore()
        .collection('classAggregates')
        .doc('class-5a')
        .update({ averageXp: 999 })
    );
  });
});

// ── Catch-all deny ────────────────────────────────────────────────────────────

describe('catch-all deny', () => {
  it('TEST-021: unknown collections are denied for all roles', async () => {
    await assertFails(
      studentCtx()
        .firestore()
        .collection('unknownCollection')
        .doc('doc1')
        .get()
    );
  });
});
