# Architecture Principles

These principles guide all codebase modifications, API designs, and plugin implementations:

### Rule #1: Never leak provider SDK types
Core interfaces must remain provider-agnostic. Adapters map vendor-specific types to platform models.

### Rule #2: Every component communicates through interfaces
Use abstract interfaces to decouple components and make implementations mockable.

### Rule #3: Plugins never access runtime internals directly
Plugins interact exclusively with the sandboxed `PluginContext` SDK.

### Rule #4: Everything observable
Trace execution paths, token budgets, and latencies via the distributed event bus.

### Rule #5: Everything testable
Every core engine, manager, and provider must maintain 100% test coverage target.

### Rule #6: Everything replaceable
Keep abstractions clean so that any database, provider, or indexer can be replaced without rewriting the core.

### Rule #7: Human approval before destructive operations
Critical execution steps, file system writes, and git commands require explicit developer confirmation.
