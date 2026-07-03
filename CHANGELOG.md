# Changelog

All notable changes to the IndiVerse Developer Platform (IDP) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] - 2026-07-03
### Added
- Completed Phase 3 Sprint 12 (Studio UI).
- Implemented a local Dart Studio HTTP Server handling REST paths for health checks, feature flags, metrics resolution, and workspace queries.
- Deployed dynamic port selector fallback mapping hunting.
- Configured a dedicated real-time event pipeline streaming WebSocket connection under `/ws/events`.
- Developed a beautiful IDE cockpit client dashboard in Flutter Web containing Workspace Explorer, Semantic search panels, Agent workflow logs, real-time metrics dashboards, and feature flags.

## [0.7.0] - 2026-07-03
### Added
- Completed Phase 3 Sprint 11 (Agent Engine).
- Standardized micro-contracts (`Agent`, `Workflow`, `Scheduler`, `Task`, `Executor`, `DecisionRecord`, `ExecutionPolicy`, `ApprovalPolicy`, `MemoryProvider`) under `contracts/`.
- Implemented task execution graph models (`WorkflowDefinition`, `WorkflowNode`, `WorkflowEdge`, `WorkflowResult`, `WorkflowSnapshot`, `WorkflowStatistics`) and validations.
- Developed `AgentExecutor` managing execution lifecycles, retries, timeouts, and cancellations.
- Evolved `AgentSession` tracking mutable stats metrics and immutable `AgentContext`.
- Programmed decoupled `PolicyValidator` delegating audits to: `SecurityPolicy`, `FilesystemPolicy`, `GitPolicy`, `BudgetPolicy`, `PluginPolicy`.
- Added context resolver compiling data from `ContextSource` options (Workspace, Knowledge, Memory, Git, Plugin, MCP, User Input).
- Programmed task queues local dispatcher queue system.
- Evolved built-in stateless executors: `PlannerAgent`, `DeveloperAgent`, `ReviewerAgent`, `TesterAgent`, `DocumentationAgent`, `SecurityAgent`.
- Formulated Platform ADR 0011 (Agent Architecture).

## [0.6.0] - 2026-07-03
### Added
- Completed Phase 3 Sprint 10 (Knowledge Engine).
- Standardized decoupled contracts (`EmbeddingProvider`, `VectorStore`, `SymbolExtractor`, `Chunker`, `SearchEngine`) under `contracts/`.
- Implemented concrete Gemini/Ollama embedding adapters and in-memory/file-simulated SQL vector stores.
- Developed Dart class regex symbol parser, markdown header parser, and json parser.
- Built multi-level cache pipelines (`EmbeddingCache`, `DocumentCache`, `GraphCache`) and index manifests validating model/dimensions upgrades.
- Programmed background reindex scheduler debouncing directory watch filesystem triggers.
- Formulated semantic query logic leveraging ranking boosts (Graph/Git/Workspace) and explainability search result payloads.
- Added platform index events telemetry log outputs.
- Formulated Platform ADR 0010 (Repository Intelligence Knowledge Engine).

## [0.5.0] - 2026-07-03
### Added
- Completed Phase 3 Sprint 9 (Workspace Engine).
- Standardized Workspace State Machine (`WorkspaceState` tracking states `closed`, `opening`, `discovering`, `indexing`, `ready`, etc.).
- Developed Extensible Discovery Pipeline (`discovery/` engine with registries supporting Flutter, Firebase, Git, Dart, Node, Python, Docker, MCP, Melos, FVM).
- Implemented file ignore scanning system and incremental indexer checking hashes.
- Constructed `WorkspaceDiagnostics` providing export mappings (JSON, Markdown, summary).
- Built ranked context builders aggregating `ContextContribution` models via README, ADR, rules, and git status providers.
- Configured budget policy rules limiting token sizes dynamically (`Tiny`, `Standard`, `Extended`, `Maximum`).
- Formulated Platform ADR 0009 (Workspace Engine).

## [0.4.0] - 2026-07-03
### Added
- Completed Phase 2 Sprint 8 (Open Source Integration Foundation).
- Introduced **Plugin SDK** (`lib/sdk/`) decoupling runtime internals from external plugins (`PluginContext`, `PluginLogger`, `PluginBuilder`, `PluginSDK`).
- Implemented **Capability-Driven Routing** matching enums (`IntegrationCapability`) to active plugins dynamically in the registry.
- Rich Lifecycle State Machine (`PluginState`: `initialized`, `activated`, `paused`, `disabled`, `failed`, `disposed`).
- Rich Health Reports (`HealthReport` tracking latency, versions, warning alerts, and error metrics).
- Environment requirements compatibility validation checks (`RuntimeCompatibility`, `PlatformCompatibility`, `DependencyCompatibility`).
- Dependency tree topological sort validation graph (`DependencyGraph`).
- Sandboxed permission rules verification (`PluginSandbox`).
- Built-in Gemini and Ollama adapter plugins.
- OpenHands, Continue, Aider, and Claude external template blueprints.
- Platform ADR 0008 (Extensible Integration Platform).

## [0.3.0] - 2026-07-03
### Added
- Completed Phase 2 Sprint 7 (Gemini Provider Adapter).
- Concrete HTTP-based `GeminiAdapter` conforming to `AIProvider` contract.
- Encapsulated HTTP client wrapper `GeminiApiClient` isolating endpoint interactions.
- Request and response serialization mappings in `GeminiRequestMapper` and `GeminiResponseMapper`.
- Capability matrix metadata matching constraints under `GeminiManifest`.
- `ProviderManifest` and `ProviderBenchmark` modeling structures under `lib/core/registry/`.
- Dynamic cost/performance telemetry tracking metrics in `BenchmarkCollector`.
- Observability diagnostics interface via `RuntimeInspector`.
- Integration tests in `gemini_provider_test.dart` checking mappings, token allocations, and status code exception translations (Rate limits, Authentications).
- Extended `exceptions.dart` to support retry metrics (`retryAfter`, `remainingRequests`).
- Restructured registries under `lib/core/registry/` for improved namespace isolation.
- Platform ADR 0007 (External AI Provider Integration).

## [0.2.0] - 2026-07-03
### Added
- Completed Phase 2 Sprint 6 (AI Runtime Foundation).
- Pluggable abstract `AIProvider` model execution system.
- Structured `AIRequest`, `AIResponse`, and `ExecutionResult` abstractions.
- Event-driven monitoring bus (`EventBus` and `RuntimeEvent`).
- Dynamic token counting, latency telemetry, and cost estimations (`TokenTracker`, `CostTracker`).
- Aggregated contextual prompts compilation flow (`ContextManager`, `PromptCompiler`).
- Chainable execution middleware (Validation, Logging, Retry with Exponential Backoff).
- Capabilites-based routing registry checks (`Capability` and `ModelMetadata`).
- Environment variable key manager bindings.
- Complete unit test suite verifying full runtime capabilities with 100% pass rates.
- Local validation integration gates run format, linting, analysis, and package tests.
- Platform ADR 0006 (AI Runtime Architecture).

## [0.1.0] - 2026-07-03
### Added
- Standardized directory layout for Sprints 0-5.
- AGENTS.md acting as the core AI Constitution.
- Reusable coding rules for Flutter, Firebase, Clean Architecture, Security, Testing, Git, and Documentation.
- Prompt library with metadata schemas.
- Agent definitions with missions, Allowed/Forbidden files, and escalation workflows.
- Integration validation scripts (`scripts/validate.sh`) and GitHub Action verify workflow.
- Initial platform ADRs (0001-0004).
