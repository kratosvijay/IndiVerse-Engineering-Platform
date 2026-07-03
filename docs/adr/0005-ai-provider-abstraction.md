# ADR 0005: AI Provider Abstraction

- **Status**: Accepted
- **Date**: 2026-07-03
- **Author**: Platform Governance Board

## Context & Problem Statement
The platform orchestrates AI-assisted development using LLMs. Directly integrating with a specific vendor's SDK locks the platform to that provider, making model upgrades or vendor switches complex and labor-intensive.

## Decision Drivers
- Need to switch or fall back to different model providers (Gemini, Claude, GPT).
- Prompts must remain reusable and provider-agnostic.
- Unified tracking of API costs and token usage.
- Normalized structured outputs.

## Decision Outcome
Establish an **AI Provider Abstraction Layer**:
1. Business logic depends only on interfaces, never on vendor concrete SDKs.
2. Prompts are kept provider-agnostic.
3. Response objects are normalized into common interface definitions.
4. Costs, limits, and tokens are tracked independently of the provider.

## Consequences
- **Positive**: Simple model upgrades, replaceable AI vendors, unified performance metrics.
- **Negative**: Implementing translation adapters for specific model configurations adds development overhead.
