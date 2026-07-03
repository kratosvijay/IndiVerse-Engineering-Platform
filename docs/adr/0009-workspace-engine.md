# ADR 0009: Workspace Engine

## Status
Accepted

## Context
When working with software projects, context needs to be collected and managed automatically. Manually specifying directories, ADRs, rules, and prompt constraints is error-prone. We need a robust Workspace Engine that discovers project layouts, indexes files, detects dependencies, and builds ranked context contributions.

## Decision
We implement a Workspace Engine with:
1. **Extensible Discovery Pipeline**: Registry of pluggable detectors scans key markers (e.g. `pubspec.yaml`, `firebase.json`).
2. **Incremental Indexer & Watcher**: Uses SHA-256 validation mapping and directory watches to only re-index changed files.
3. **Decoupled Context Providers**: Subsystems contribute context chunks independently, which are ranked by priority closeness and constrained to token budgets.

## Consequences
- **Pros**:
  - Automatically loads and configures workspace context.
  - Zero manual prompt selections.
- **Cons**:
  - Directory watcher resources allocation.
