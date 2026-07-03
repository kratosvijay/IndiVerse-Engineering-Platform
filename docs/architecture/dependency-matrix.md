# Dependency Matrix

This document defines the import restrictions and architectural layering rules for the IndiVerse Developer Platform (IDP).

## Layer Import Matrix

| Layer | Can Import | Forbidden Imports |
|---|---|---|
| **Studio (UI)** | Platform SDK, Agent API | Knowledge Engine, Workspace Engine, Runtime, Provider Adapters |
| **Agent Engine** | Knowledge Engine API, Workspace Engine API, Platform Event Bus | Studio UI, Runtime Internals, Provider Adapters |
| **Knowledge Engine** | Workspace Engine API, Platform Event Bus | Studio UI, Agent Engine, Runtime Internals, Provider Adapters |
| **Workspace Engine** | Plugin Platform SDK, Platform Event Bus | Studio UI, Agent Engine, Knowledge Engine, Runtime, Provider |
| **Plugin Platform** | AI Runtime API, Platform Event Bus | Studio UI, Agent Engine, Knowledge Engine, Workspace Engine, Provider |
| **AI Runtime** | Provider Adapter APIs, Platform Event Bus | Studio UI, Agent Engine, Knowledge Engine, Workspace Engine, Plugins |
| **Provider Adapters**| Model Registry Models | Studio UI, Agent Engine, Knowledge Engine, Workspace Engine, Plugins, Runtime |

## Architectural Enforcement Rules
1. **Direction of Dependencies**: Imports must flow strictly downwards from orchestrators to platforms and runtimes.
2. **Forbidden Circular Routing**: Circular loops (e.g. Workspace importing Agent details) will fail static analysis gates.
3. **Contracts Isolation**: Core modules must interact strictly using interfaces declared in their corresponding `contracts/` directories.
