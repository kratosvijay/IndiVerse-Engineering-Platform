# ADR 0004: Prompt Metadata Standard

- **Status**: Accepted
- **Date**: 2026-07-03
- **Author**: Platform Governance Board

## Context & Problem Statement
Generic prompts are hard to test and reuse. We need a structured format for all prompt templates.

## Decision Outcome
Mandate that all prompts under the `prompts/` folder include structured headers: Name, Purpose, Inputs, Outputs, Constraints, Example, and Expected Result.

## Consequences
- **Positive**: Prompts become testable assets.
- **Negative**: Slightly higher effort when writing prompts.
