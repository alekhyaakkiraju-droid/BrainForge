// Initialize Firebase Admin SDK before any other imports that depend on it.
import "./config/admin";

export { healthCheck } from "./health/healthCheck";
export { recordConsent } from "./auth/consentService";
export { createChildAccount, childSignIn } from "./auth/childAccountService";
