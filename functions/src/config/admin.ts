import * as admin from "firebase-admin";

// Initialized once at module load; subsequent imports share this instance.
// When running inside the Functions emulator the SDK auto-detects credentials,
// so we only pass an explicit credential in the real cloud environment.
if (!admin.apps.length) {
  admin.initializeApp();
}

export { admin };
