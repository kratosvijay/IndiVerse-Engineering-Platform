# Architecture Principles

This document defines the engineering constitution of the IndiVerse Developer Platform. All core platform development, SDK evolution, plugin implementations, and architectural reviews must comply with these principles unless an approved Architecture Decision Record (ADR) explicitly documents an exception.

These principles are mandatory for all core platform components, SDKs, plugins, and future architectural decisions. When trade-offs arise, they should be documented through an Architecture Decision Record (ADR) before implementation.

These principles guide all codebase modifications, API designs, and plugin implementations:

---

## 🏗️ Architecture
### 1. Never leak provider SDK types
Core interfaces must remain provider-agnostic. Adapters map vendor-specific types to platform models.

### 2. Every component communicates through interfaces
Use abstract interfaces to decouple components and make implementations mockable.

### 3. Everything replaceable
Keep abstractions clean so that any database, provider, or indexer can be replaced without rewriting the core.

---

## 🔌 Platform
### 4. Plugins never access runtime internals directly
Plugins interact exclusively with the sandboxed `PluginContext` SDK.

### 5. Security by Default
Every new capability must follow the principle of least privilege. Permissions are denied by default and explicitly granted through the manifest. Sensitive data must never be stored or transmitted unencrypted.

### 6. Offline First
Core platform capabilities must continue functioning without network access wherever practical. Indexing, workspace analysis, context building, and cached knowledge should operate locally.

---

## 🎯 Quality
### 7. Everything observable
Trace execution paths, token budgets, and latencies via the distributed event bus.

### 8. Everything testable
Every core engine, manager, and provider must maintain 100% test coverage target.

### 9. Human approval before destructive operations
Critical execution steps, file system writes, and git commands require explicit developer confirmation.

---

## 📈 Evolution
### 10. Open Standards Before Proprietary Extensions
When an industry-standard protocol exists (such as MCP, Git, LSP, or DAP), prefer implementing and extending that standard before introducing proprietary APIs.

### 11. AI Decisions Must Be Explainable
Every AI-generated recommendation should expose sufficient reasoning, context sources, and execution history for a developer to review.

### 12. Backward Compatibility First
Public SDKs, plugin APIs, and stable platform contracts should remain backward compatible throughout a major release. Breaking changes require a new ADR, migration documentation, and a major version increment.

---

## ⚖️ Precedence
When principles appear to conflict, resolve them in the following order:
1. **Security**
2. **Correctness**
3. **Architecture**
4. **Reliability**
5. **Performance**
6. **Developer Experience**

Any intentional deviation must be documented in an ADR.

---

## 👮 Enforcement
These principles are enforced through:
- **Architecture Review Checklist**: Evaluated during design and code reviews.
- **Pull Request Review Process**: PR templates require explicit compliance validation.
- **Architecture Decision Records (ADRs)**: Exposing exceptions and architectural trade-offs explicitly.
- **Automated Validation**: Running `dart analyze`, `dart test`, and custom validation gates.
- **CI Pipelines**: Rejecting non-conforming builds.

---

## 📋 Compliance Checklist
Reviewers and contributors must verify the following gates:
- [ ] **Provider SDKs**: Do not leak vendor-specific types into core layers.
- [ ] **Interface Driven**: Every new dependency behaves through decoupled abstract contracts.
- [ ] **Plugin Sandbox**: Filesystem access is strictly sandboxed.
- [ ] **Security by Default**: Least privilege rule respected.
- [ ] **Offline First**: Offline caching capability is preserved.
- [ ] **Observable**: Cost tracking and event bus triggers are instrumented.
- [ ] **Testable**: Clean test coverage gates are satisfied.
- [ ] **Human Approval**: Mandatory prompt validation gates for destructive mutations are preserved.
- [ ] **Open Standards**: Standards-compliant protocols (like MCP/Git) are prioritized.
- [ ] **Explainable AI**: Reasoning maps and context source histories are exposed.
- [ ] **Backward Compatible**: Breaking stable contracts are prohibited.


