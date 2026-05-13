import { onRequest } from "firebase-functions/v2/https";

/**
 * Resolves the logical environment name from the GCLOUD_PROJECT env var so
 * callers can verify which Firebase project is backing this deployment without
 * exposing internal project IDs verbatim.
 */
function resolveEnvironment(): string {
  const project = process.env.GCLOUD_PROJECT ?? "";
  if (project.endsWith("-prod")) return "production";
  if (project.endsWith("-staging")) return "staging";
  if (project.endsWith("-dev")) return "development";
  // Emulator or unknown — treat as development.
  return "development";
}

export const healthCheck = onRequest((req, res) => {
  res.status(200).json({
    status: "ok",
    environment: resolveEnvironment(),
  });
});
