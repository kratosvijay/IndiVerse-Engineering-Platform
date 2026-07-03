# ADR 0014 — Workbench Architecture Freeze

## Status
Accepted

## Context
As IndiVerse Studio evolves from a dashboard application into a professional development environment, we need a stable structural framework. To prevent architectural drift, ensure backward compatibility for future plugins, and guarantee clean integration with LSP backends and AI agents, we must establish a frozen v1 architecture.

## Decision
The Workbench v1 Architecture is officially frozen.
1. The layered layout is locked: `Widgets` ➔ `WorkbenchApiV1` ➔ `Domain APIs / Providers` ➔ `DocumentService` ➔ `WorkbenchEventBus` ➔ `PlatformSDK`.
2. All UI components interact exclusively through the `WorkbenchApi` facade using strongly-typed IDs.
3. Asynchronous APIs return standard `OperationResult<T>` and `WorkbenchError` envelopes, supporting `CancellationToken` capability.
4. Any future architectural modification requires a formal ADR review and approval.

## Consequences
### Pros
- Stable API surfaces for plugin authors and AI agents.
- Reduced risk of coupling regression across features.
- Faster implementation velocity on top of a mature platform.

### Cons
- Structural modifications require formal ADR revision.
