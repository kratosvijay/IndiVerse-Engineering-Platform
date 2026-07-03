# IndiVerse Developer Platform (IDP) - v2.0 Roadmap

This document outlines the evolutionary steps of the IDP from foundational phases to the production-ready General Availability (GA) release and the long-term autonomous engineering platform vision.

## 🌟 Core Principles
Every design decisions and implementations must conform to these core tenets:
- **Provider Agnostic**: The system does not depend on a single vendor or API model.
- **Event Driven**: Components communicate through asynchronous state dispatchers.
- **Plugin First**: Integrations are isolated sandbox plugins built on the SDK.
- **Offline First**: Cache data and compile indices locally.
- **Secure by Default**: Explicit permission controls and sandboxed file-system rules.
- **AI Native**: Orchestrates capabilities explicitly mapped to LLM APIs.
- **Observable**: Distributed telemetry, cost tracing, and execution tracking.
- **Testable**: Absolute unit test coverage requirements for platform engines.
- **Extensible**: Simple base interfaces allow community extensions.
- **Open Standards**: Standard protocols (like Model Context Protocol) guide interfaces.

---

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
| **v1.0.0**| General Availability (GA) | ⬜ Planned | Production stable, plugin marketplace ready, installer, LTS support |
| **v1.1** | Distributed AI Execution | ⬜ Planned | Multiple Gemini Keys load balancing, failover queue, parallel agents |
| **v2.0** | Autonomous Platform | ⬜ Planned | Autonomous sprint planning, multi-repo, AI architecture evolution |

---

## 🎯 Success Metrics

| Version | Success Criteria |
|---|---|
| **v0.6** | Semantic search returns relevant results in < 500 ms for indexed repositories |
| **v0.7** | Coordinated workflows (e.g. planner + reviewer + tester) complete successfully |
| **v0.8** | Core workflows executed smoothly without relying on CLI commands |
| **v0.9** | Native compatibility with standard external MCP clients and servers |
| **v1.0.0**| Stable and secure enough for daily platform development on IndiVerse apps |
| **v1.1** | Multi-key load balancing and worker queues improve platform throughput |
| **v2.0** | Autonomous planning pipelines assist developer flows while remaining reviewable |

---

## 🚀 Phase Details

### Phase 1: Foundations (v0.1 - Complete)
Establish coding standards, linting, AI prompt structures, and CI validation pipelines to ensure high-fidelity codebase modifications.

### Phase 2: Runtime & Extensible Platform (v0.2 - v0.4 - Complete)
- **v0.2**: Provider-agnostic engine executing prompts through middleware pipelines.
- **v0.3**: Seamless API client mapping to Google's Gemini models with stream splitters.
- **v0.4**: Secure Plugin SDK allowing community integrations (e.g. Ollama, Continue) to run with sandbox controls.

### Phase 3: Developer Intelligence (v0.5 - v1.0.0 - Active)
- **v0.5 (Sprint 9 - Workspace Engine)**: Automates project detection and context assemblies.
- **v0.6 (Sprint 10 - Knowledge Engine)**: Indexes source code, embeddings, and semantic ADR references.
- **v0.7 (Sprint 11 - Agent Engine)**: Run cooperative developer workflows (Planners, Reviewers, Testers).
- **v0.8 (Sprint 12 - Studio)**: Lightweight developer cockpit.
- **v0.9 (Sprint 13 - MCP)**: Native MCP Client/Server integration.
- **v1.0.0 (GA)**: Enterprise stabilization, security audit, and LTS support.

### Phase 4: Scaling & Failover (v1.1 - Planned)
- **v1.1 (Distributed AI Execution)**: Parallel task execution queues, multi-key load balancing, and remote worker failovers.

### Phase 5: Long-Term Vision (v2.0 - Planned)
- **v2.0 (Autonomous Engineering Platform)**: Multi-repository orchestration, cross-project knowledge sharing, and autonomous sprint planning integrations.

---

## 👥 Adoption Targets
- **Alpha**: Internal IndiVerse product teams (IndiCabs, TeamOS, School ERP).
- **Beta**: Trusted external developers.
- **Release Candidate (RC)**: Small teams and pilot integrations.
- **General Availability (GA)**: Public developers and enterprise integrations.

---

## 🔌 Enterprise Connectors (v1.x - Built as Plugins)
Connector integrations will be built as external plugins using the SDK:
- **Source Control**: GitHub, GitLab.
- **Planning & Comms**: Jira, Linear, Slack, Discord.
- **Data & Ops**: Firebase, Supabase, PostgreSQL, Docker, Kubernetes.
- **Environments**: Figma, VS Code extension, Android Studio plugin.

---

## 🛠️ Cross-Cutting Platform Services
Consistent telemetry, tracing, metrics, and health checks are exposed to all layers:
- **Telemetry**: Distributed event bus tracing execution chains.
- **Metrics**: Token usage, cost estimations, and rolling average latency tracking.
- **Logging**: Sandboxed logger per plugin.
- **Diagnostics**: Snapshots exportable to JSON/Markdown.


