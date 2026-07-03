# Prompt: Semantic Changelog Generator

- **Name**: Changelog Builder
- **Purpose**: Generate changelogs from semantic commit messages.
- **Inputs**: List of commits since last tag.
- **Outputs**: Changelog text grouped by Added, Changed, Fixed, and Removed.
- **Constraints**: Only process messages conforming to the semantic commit rules.
- **Example**: Git commits from v0.1.0 to v0.2.0.
- **Expected Result**: Structured markdown changelog fragment.
