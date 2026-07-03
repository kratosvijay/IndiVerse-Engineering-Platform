# IndiVerse Developer Platform (IDP) - Roadmap

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
| **v0.95**| Performance & Hardening | ⬜ Planned | Memory profiling, startup optimization, security audits, load benchmarks |
| **v1.0.0**| General Availability (GA) | ⬜ Planned | Production stable, plugin marketplace ready, installer, LTS support |
| **v1.1** | Distributed AI Execution | ⬜ Planned | Multiple Gemini Keys load balancing, failover queue, parallel agents |
| **v2.0** | Autonomous Platform | ⬜ Planned | Autonomous sprint planning, multi-repo, AI architecture evolution |
| **v3.x** | Ecosystem | ⬜ Planned | Hosted runtime, Cloud Workspace Sync, Hosted Knowledge/Agents |

> [!NOTE]
> The engine milestones follow a strict, layered dependency chain:
> **Workspace Engine** (discovers files) $\rightarrow$ **Knowledge Engine** (indexes and generates embeddings) $\rightarrow$ **Agent Engine** (consumes knowledge to collaborate) $\rightarrow$ **Studio** (visualizes & orchestrates all runtimes).

---

## 🎯 Success Metrics

| Version | Success Criteria |
|---|---|
| **v0.6** | Semantic search returns relevant results in < 500 ms for indexed repositories |
| **v0.7** | Coordinated workflows (e.g. planner + reviewer + tester) complete successfully |
| **v0.8** | Core workflows executed smoothly without relying on CLI commands |
| **v0.9** | Native compatibility with standard external MCP clients and servers |
| **v0.95**| Zero memory leaks detected and startup index initialization optimized to < 150ms |
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
- **v0.95 (Sprint 14 - Performance & Hardening)**: Complete comprehensive validation including:
  - Memory profiling & leak detection
  - Startup initialization profiling
  - Large repository load benchmarks
  - Plugin stress and sandboxing testing
  - Crash recovery & failover validation
  - Security penetration testing
  - Compatibility regression suite execution
  - Golden repository automated verification
- **v1.0.0 (GA)**: Enterprise stabilization and LTS support.

### Phase 4: Scaling & Failover (v1.1 - Planned)
- **v1.1 (Distributed AI Execution)**: Parallel task execution queues, multi-key load balancing, and remote worker failovers.

### Phase 5: Long-Term Vision (v2.0 - Planned)
- **v2.0 (Autonomous Engineering Platform)**: Multi-repository orchestration, cross-project knowledge sharing, and autonomous sprint planning integrations.

### Phase 6: Ecosystem Growth (v3.x - Planned)
- **v3.x (Ecosystem)**: Cloud workspace syncing for teams, hosted agents pipelines, hosted knowledge retrieval databases, and hosted AI runtimes.

---

## ⚙️ Compatibility Matrix
- **Flutter**: Latest stable release branch.
- **Dart**: Latest stable SDK release.
- **Firebase**: Current CLI tools and FlutterFire modules.
- **Gemini API**: Current public stable endpoint models.
- **MCP**: Stable Model Context Protocol v1.x specification.
