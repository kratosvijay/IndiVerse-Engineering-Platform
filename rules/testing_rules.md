# Testing & Verification Rules

Test criteria to verify code correctness.

## Test Boundaries
- **Unit Tests**: Required for all domain use-cases, validators, and entities. Aim for 80% coverage.
- **Integration Tests**: Verify core database transaction flows, auth cycles, and functions.
- **Golden Tests**: Mandated for reusable design system components to prevent visual regression.
- **UI Tests**: Focus on critical passenger workflows using Maestro or equivalent tools.
