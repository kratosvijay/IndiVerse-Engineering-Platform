# Contributing to IDP

Thank you for contributing to the IndiVerse Developer Platform (IDP)!

## Branching & Pull Requests
- Create a new branch for each feature or bug fix: `feat/` or `fix/`.
- Pull requests must pass all quality gates: `dart format`, `dart analyze`, and `dart test`.
- All PRs require review and approval before merging into `main`.

## ADR Workflow
- Major architectural changes must be proposed via an Architecture Decision Record (ADR) under `docs/adr/`.
- File names must follow `XXXX-description.md` format (e.g., `0009-workspace-engine.md`).

## Coding Standards & Testing
- Keep code clean, modular, and conform to the Engineering Constitution.
- Any new features must be accompanied by comprehensive unit tests.
- Verify platform stability using: `bash scripts/validate.sh`.
