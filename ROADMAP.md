# IndiVerse Developer Platform (IDP) - v1.0 Roadmap

This document outlines the evolutionary steps of the IDP from the foundational phases to the production-ready v1.0 enterprise release.

## 🗺️ Roadmap Overview

| Version | Phase / Goal | Status | Focus Area |
|---|---|---|---|
| **v0.1** | Engineering Foundation | ✅ Complete | Constitutions, coding standards, prompt frameworks, validation templates |
| **v0.2** | AI Runtime | ✅ Complete | Event-driven runtime core, pipeline middlewares, budget and token tracking |
| **v0.3** | Gemini Adapter | ✅ Complete | Pluggable vendor clients, serialization mappers, SSE streaming |
| **v0.4** | Plugin Platform | ✅ Complete | Sandboxed Plugin SDK, state machines, permission validators, graphs |
| **v0.5** | Workspace Engine | ✅ Complete | Multi-project discovery, framework detection (Flutter/Firebase), indices |
| **v0.6** | Knowledge Engine | ⬜ Planned | Embeddings generation, vector search, semantic code search, memory |
| **v0.7** | Agent Engine | ⬜ Planned | Multi-agent coordination (Planners, Developers, Testers, Reviewers) |
| **v0.8** | Studio | ⬜ Planned | Minimal desktop explorer UI, diagnostics panel, token/cost dashboards |
| **v0.9** | MCP | ⬜ Planned | Native Model Context Protocol (MCP) servers client integrations |
| **v1.0** | Enterprise Release | ⬜ Planned | Production hardening, crash recovery, documentation freeze, release |

---

## 🚀 Phase Details

### Phase 1: Foundations (v0.1 - Complete)
Establish coding standards, linting, AI prompt structures, and CI validation pipelines to ensure high-fidelity codebase modifications.

### Phase 2: Runtime & Extensible Platform (v0.2 - v0.4 - Complete)
- **v0.2**: Provider-agnostic engine executing prompts through middleware pipelines.
- **v0.3**: Seamless API client mapping to Google's Gemini models with stream splitters.
- **v0.4**: Secure Plugin SDK allowing community integrations (e.g. Ollama, Continue) to run with sandbox controls.

### Phase 3: Developer Intelligence (v0.5 - v1.0 - Active)
- **v0.5 (Sprint 9 - Workspace Engine)**: Automates project detection and context assemblies.
- **v0.6 (Sprint 10 - Knowledge Engine)**: Indexes source code and semantic ADR references.
- **v0.7 (Sprint 11 - Agent Engine)**: Run cooperative developer workflows.
- **v0.8 (Sprint 12 - Studio)**: Lightweight developer cockpit.
