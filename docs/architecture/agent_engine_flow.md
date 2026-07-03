# Agent Engine Flow

This document details the pipeline execution flow within the Agent Engine.

```text
Workflow Graph (Nodes & Edges)
          │
          ▼
   Task Scheduler (Task Queue)
          │
          ▼
   Agent Registry (Capability Match)
          │
          ▼
   Agent Context (Workspace & Knowledge snapshots)
          │
          ▼
   Knowledge Engine Retrieval
          │
          ▼
    AI Runtime (Adapter Prompts Execution)
          │
          ▼
    Decision Record (Telemetry stats mapping)
          │
          ▼
    Human Review Approval Gate
          │
          ▼
        Result Output (Task Completed event)
```
