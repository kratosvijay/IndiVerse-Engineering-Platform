# Extension Points

This document details where and how developers can extend the IndiVerse Developer Platform (IDP) capabilities.

## Extension Hooks

| Extension Point | Target Directory | Interface Contract |
|---|---|---|
| **AI Model Provider** | `lib/core/registry/` | `AIProvider` |
| **Integrations Plugin** | `lib/sdk/` | `Plugin` |
| **Workspace Detectors** | `lib/core/workspace/discovery/` | `Detector` |
| **Language Symbol Extractors** | `lib/core/knowledge/extractors/` | `SymbolExtractor` |
| **Micro-Agents** | `lib/core/agent/agents/` | `Agent` |
| **Task Schedulers** | `lib/core/agent/scheduler/` | `Scheduler` |
