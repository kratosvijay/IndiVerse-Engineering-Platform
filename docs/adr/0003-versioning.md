# ADR 0003: Platform Versioning Strategy

- **Status**: Accepted
- **Date**: 2026-07-03
- **Author**: Platform Governance Board

## Context & Problem Statement
The IDP contains critical standards. Changes to coding rules or templates must be tracked to support backwards compatibility across client projects.

## Decision Outcome
Introduce a single-source-of-truth `VERSION` file in the repository root and utilize Semantic Versioning (SemVer) for updates.

## Consequences
- **Positive**: Clear release boundaries.
- **Negative**: Requires strict version increment discipline.
