# Prompt: API Security Verification Guard

- **Name**: Request Parameter Security Guard
- **Purpose**: Generates security validation guards for endpoints or function triggers.
- **Inputs**: Parameter keys, validation constraints, authentication validation.
- **Outputs**: Secure validation middleware or logic blocks.
- **Constraints**: Default to throwing exceptions if authentication context is missing.
- **Example**: `processPayment` request params validation.
- **Expected Result**: Hard parameter check and auth role assertion before business logic.
