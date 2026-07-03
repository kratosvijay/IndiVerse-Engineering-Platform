# Prompt: Cloud Functions Idempotent Endpoint Generator

- **Name**: Cloud Functions Endpoint Builder
- **Purpose**: Scaffold safe Serverless actions.
- **Inputs**: Trigger type, parameters, database interactions.
- **Outputs**: TypeScript Cloud Function endpoint code.
- **Constraints**: Require transaction atomic constraints and idempotency check.
- **Example**: `cancelBooking`.
- **Expected Result**: Decoupled cloud function.
