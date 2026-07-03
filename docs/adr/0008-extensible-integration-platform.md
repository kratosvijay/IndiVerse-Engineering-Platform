# ADR 0008: Extensible Integration Platform

## Status
Accepted

## Context
To scale the IDP efficiently, we must avoid writing custom orchestrators and tools for every developer workflow. Instead, we want to integrate mature, open-source developer toolings (e.g., Ollama, OpenHands, Continue, Aider) in a generic, capability-driven way without cluttering runtime core interfaces or hardcoding external dependencies.

## Decision
We introduce the **Plugin SDK** and a capability-driven integration system.

1. **Plugin SDK Isolation**:
   - Plugins only interact with the `PluginContext` (exposing EventBus, Credentials, and Runtime wrapper interfaces), isolating internal runtime concerns.
2. **Capability-Driven Routing**:
   - Integrations declare supported capabilities (`IntegrationCapability` enum) in their manifest instead of subclassing specific adapters.
   - The registry dynamically routes commands and capabilities checks based on available active plugins.
3. **Compatibility & Verification**:
   - Every integration has min/max runtime and binary dependency requirements checked by the `CompatibilityManager` prior to initialization.

## Consequences
- **Pros**:
  - Decoupled framework: the core runtime has ZERO awareness of OpenHands, Ollama, or custom scripts.
  - Pluggable extension ecosystem: plugins can be installed, enabled, or paused dynamically.
- **Cons**:
  - Requires writing wrapper manifests and lifecycles for external binaries.
