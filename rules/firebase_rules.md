# Firebase Standards & Coding Rules

Operating rules for Firebase authentication, Firestore, cloud functions, and database triggers.

## Firestore Schema & Write Boundaries
- All updates to critical financial or user records must occur through transactions or backend Cloud Functions.
- Direct database writes must pass strict validation inside `firestore.rules`.
- Real-time snapshot listeners must specify target collections cleanly to avoid excessive read costs.

## Cloud Functions
- Standardize on Node.js 22 and TypeScript.
- Implement idempotency checks for all payment and transaction hooks.
- Use structured logging (`logger.info`, `logger.warn`) and redact PII.
