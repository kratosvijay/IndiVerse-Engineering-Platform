# ADR 0013: Release Qualification & Stability Policy

## Status
Accepted

## Context
As the platform moves to version `v0.95.0` (Performance & Hardening) and approaches General Availability (`v1.0.0`), we must ensure the core runtime, workspace indexers, knowledge search capabilities, and agent workflow engines conform to strict quality guidelines. We need to define explicit performance budgets, security audits, and reliability validation rules.

## Decision
We implement a Release Qualification & Stability Policy containing the following enforcement criteria:

1. **Performance Budgets & Limits**:
   - Every build must pass performance budget validations. Limits are defined as:
     - **Cold Startup Latency**: $<150$ ms.
     - **Workspace Discovery**: $<500$ ms.
     - **Semantic Search Retrieval**: $<500$ ms.
     - **Agent Queue Dispatch**: $<50$ ms.
     - **MCP Request Latency**: $<100$ ms.
     - **Plugin Load Latency**: $<75$ ms.
2. **Memory Leak Checks**:
   - Track memory profiles across core stages (Idle, Workspace loaded, indexed, active runs). Memory growth checks must detect and fail on leak patterns.
3. **Security Auditing Gates**:
   - Perform audits on file traversals, directory sandboxing, symbolic links, shell command validation, secret key redactions, and prompt injection sanitization.
4. **Reliability & Stress Testing**:
   - Run stress execution passes (e.g. 100 scans, 1000 search queries) verifying automated retry recovery under network timeouts, rate limit errors, and database file corruptions.
5. **Release Gate Checklist**:
   - The platform qualifies for release tagging only if:
     - `dart analyze` contains `0` issues.
     - `dart test` executes 100% green.
     - Benchmarks meet performance budgets.
     - Security audit scans pass.
     - Dependency matrix rules are verified with zero circular imports.
6. **Release Repeatability**:
   - Two consecutive release qualification runs on the same commit must produce equivalent pass/fail results (excluding expected timing variance).
7. **Unified Qualification Tooling**:
   - We enforce a single release qualification command: `dart run tool/release_qualification.dart` which automates all gates and exports compile-time reports under `reports/`.

## Directory Structure

```text
benchmark/
├── startup/
│   └── startup_benchmark.dart
├── workspace/
│   └── workspace_benchmark.dart
├── knowledge/
│   └── knowledge_benchmark.dart
├── agent/
│   └── agent_benchmark.dart
├── runtime/
│   └── runtime_benchmark.dart
├── mcp/
│   └── mcp_benchmark.dart
└── reports/
    ├── startup.json
    ├── memory.json
    ├── benchmark.json
    ├── security.json
    ├── compatibility.json
    └── qualification_report.json
```

## Consequences
- **Pros**:
  - Enforces objective, measurable quality standards prior to release.
  - Prevents architectural regressions.
- **Cons**:
  - Increases CI/CD validation durations.
