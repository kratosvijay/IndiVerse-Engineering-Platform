# Adoption Guide: Firebase Environments

Guidelines for adopting the IDP in a serverless Firebase backend:

1. **Verify Versions**: Use Node.js 22 and TypeScript in `functions/package.json`.
2. **Hardened Access**: Apply the security patterns defined in `rules/security_rules.md` to `firestore.rules`.
3. **Structured Logs**: Wrap function executions with the observability trace patterns.
