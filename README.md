# IndiVerse Developer Platform (IDP)

Welcome to the **IndiVerse Developer Platform (IDP)**, the centralized engineering operating system for all IndiVerse products. The IDP standardizes AI-assisted development, clean architecture paradigms, coding styles, verification pipelines, templates, and developer experience tools.

## 🚀 Vision
Every standard, prompt, and utility in this platform is versioned, reviewed, and tested. The IDP is a software product, not static documentation.

## 📂 Layout Overview
- `docs/`: Comprehensive architecture guides, roadmaps, and adoption checklists.
- `rules/`: Machine-readable and AI-parseable coding conventions.
- `templates/`: Structured markdown templates for ADRs, pull requests, issues, and architectures.
- `prompts/`: Metadata-enriched AI prompt framework for high-fidelity code generation.
- `agents/`: Autonomous AI agent definitions, permissions, and escalation guidelines.
- `governance/`: Standards for deprecation, decisions, and platform versioning.
- `scripts/`: Local validation toolchains and developer scaffolding.
- `mcp/`: Integrations for Model Context Protocol.

## 📦 Getting Started
To verify the repository files locally, run:
```bash
bash scripts/validate.sh
```
All pull requests must pass the CI quality gates defined in `.github/workflows/verify_platform.yml`.

## 🤖 AI Runtime Core (v0.3.0)
The IDP contains a vendor-agnostic, event-driven Dart AI Runtime inside the `lib/core` directory. Key features include:
- **Capability Routing**: Matches requests to provider models dynamically (Text, Vision, Tool Calling, etc.).
- **Pluggable Middleware Pipeline**: Custom interceptors (Validation, Logging, Exponential Backoff Retries).
- **Benchmark & Health Tracking**: Tracks latency percentiles (P50, P95, P99), costs, and rates to route around failures.
- **Provider Adapters**: Gemini adapter (`lib/core/providers/gemini`) utilizing split HTTP clients, serializers, and SSE streams.
