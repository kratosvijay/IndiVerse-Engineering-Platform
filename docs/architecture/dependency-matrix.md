# Dependency Matrix & Architecture Reference

This document defines the compile-time, runtime, event-driven, and classification rules for the IndiVerse Developer Platform (IDP).

## Dependency Classifications

| Layer | Compile-time Imports | Runtime Allowed Calls | Events Published / Consumed |
|---|---|---|---|
| **Studio (UI)** | `PlatformSDK` API | `PlatformSDK` | None / Consumes `WorkflowEvents`, `TaskEvents` |
| **Agent Engine** | `Knowledge API`, `Workspace API` | `KnowledgeEngine`, `WorkspaceManager` | `WorkflowEvents`, `TaskEvents` / `WorkspaceEvents` |
| **Knowledge Engine** | `Workspace API` | `WorkspaceManager` | `KnowledgeEvents` / `WorkspaceEvents` |
| **Workspace Engine** | `Plugin Platform SDK` | `PluginRegistry` | `WorkspaceEvents` / None |
| **Plugin Platform** | `AI Runtime API` | `RuntimeExecutor` | `PluginEvents` / None |
| **AI Runtime** | `Provider Adapter APIs` | `AIProvider` | `RuntimeEvents` / None |
| **Provider Adapters**| None | None | None / None |

---

## Public vs Internal & Stability Matrix

| Module | Classification | Stability Level | Ownership |
|---|---|---|---|
| `lib/core/runtime/` | Public | Stable | AI Runtime Team |
| `lib/core/workspace/` | Public | Stable | Workspace Team |
| `lib/core/knowledge/` | Public | Stable | Repository Intelligence Team |
| `lib/core/agent/` | Public | Stable | Orchestration Team |
| `lib/platform_sdk/` | Public Facade | Stable | Platform SDK Team |
| `lib/core/internal/` | Internal | Private | Platform Core Maintainers |
| `lib/core/experimental/`| Internal | Experimental | Experimental WG |

---

## Platform Facade (Platform SDK) Layer

To prevent the Studio UI layer from direct coupling to core engine internals, the **Platform SDK** acts as the single gateway facade. All UI clients, CLI instances, VS Code plugins, or MCP servers interface exclusively through the SDK:

```text
Studio UI / CLI Client
          │
          ▼
     Platform SDK (lib/platform_sdk/)
          │
          ├──────────────┬──────────────┬──────────────┐
          ▼              ▼              ▼              ▼
      Agent API    Knowledge API  Workspace API  Runtime API
```

---

## Architectural Enforcement Metrics
To prevent architectural drift over time, releases track the following structural constraints:
- **Circular Imports**: Target is exactly `0`.
- **Analyzer Warnings**: Target is exactly `0`.
- **Public API Surface Size**: Measured in total exported contracts.
- **Maximum Dependency Depth**: Restricted to `6` layers max.
