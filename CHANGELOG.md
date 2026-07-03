# Changelog

All notable changes to the IndiVerse Developer Platform (IDP) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
