# ADR 0014 — Workbench Architecture Freeze

## Status
Accepted

## Context
As IndiVerse Studio evolves from a dashboard application into a professional development environment, we need a stable structural framework. To prevent architectural drift, ensure backward compatibility for future plugins, and guarantee clean integration with LSP backends and AI agents, we must establish a frozen v1 architecture.

## Decision
The Workbench v1 Architecture is officially frozen.

### 1. Dependency Matrix Rules
The allowed import directions are strictly constrained as follows:

| Layer | May Depend On |
| --- | --- |
| **UI Widgets** | `WorkbenchApi` only |
| **WorkbenchApi** | `Domain APIs` |
| **Domain APIs** | `Providers`, `DocumentService` |
| **DocumentService** | `PlatformSDK` |
| **PlatformSDK** | Backend REST / WebSocket |
| **Backend** | Core Runtime |

#### Forbidden Imports:
- UI ➔ PlatformSDK
- UI ➔ Core Runtime
- Provider ➔ UI
- PlatformSDK ➔ Flutter Widgets
- Core ➔ Studio UI

### 2. Workbench API Facade Stability
We classify the `WorkbenchApiV1` facade methods into stability tiers:

| API Tier | Methods |
| --- | --- |
| **Stable** | `openFile()`, `closeFile()`, `jumpToLine()`, `revealInExplorer()`, `search()` |
| **Experimental** | `semanticTokens()`, `hover()`, `completion()` |
| **Reserved** | `rename()`, `format()` |

### 3. Workbench Performance Budgets
To keep the UI responsive and fast, we enforce the following latency budgets:

| Operation | Budget |
| --- | --- |
| Open file | <50 ms |
| Switch tab | <16 ms |
| Reveal in explorer | <30 ms |
| Outline generation | <100 ms |
| Go to definition | <150 ms |
| Find references | <500 ms |
| Search debounce | 250 ms |
| Workspace refresh | <500 ms |

## Consequences
### Pros
- Stable API surfaces for plugin authors and AI agents.
- Reduced risk of coupling regression across features.
- Faster implementation velocity on top of a mature platform.

### Cons
- Structural modifications require formal ADR revision.
