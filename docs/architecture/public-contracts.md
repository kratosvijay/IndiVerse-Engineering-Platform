# Public Contracts

This document identifies the frozen public contracts that third-party developers, plugin authors, and external orchestrators can depend on.

## Stable Public APIs (v1.0 Commitments)

### 1. AI Runtime
- `AIProvider` (provider wrapper execution interface)
- `AIRequest` / `AIResponse` payloads

### 2. Plugin Platform
- `Plugin` interface
- `PluginContext` sandboxed filesystem and command executor

### 3. Workspace Engine
- `WorkspaceState` lifecycle hooks
- `ContextProvider` context gathering pipeline interface

### 4. Knowledge Engine
- `EmbeddingProvider` contract
- `VectorStore` database contract
- `SymbolExtractor` parsing contract
- `Chunker` file chunker contract

### 5. Agent Engine
- `Agent` stateless micro-agent executor contract
- `Scheduler` workflow task scheduler contract
- `Workflow` graph contract
- `ExecutionPlan` contract
- `AgentContext` execution context
- `DecisionRecord` explainability metadata payload
- `MemoryProvider` memory cache contract
