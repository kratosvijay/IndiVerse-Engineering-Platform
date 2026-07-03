# Prompt: AI Pull Request Security Auditor

- **Name**: AI PR Security Auditor
- **Purpose**: Audits diffs for security vulnerabilities.
- **Inputs**: Git diff file.
- **Outputs**: Detailed analysis of security alterations (rules, functions, variables).
- **Constraints**: Strict verification of authentication context modifications.
- **Example**: Diff modifying Firestore rules.
- **Expected Result**: Security alert warnings if rules are made more permissive.
