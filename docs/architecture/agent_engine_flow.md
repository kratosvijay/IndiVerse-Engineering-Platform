# Agent Engine Flow

This document details the pipeline execution flow within the Agent Engine.

```text
Workflow Definition
        │
        ▼
Workflow Executor
        │
        ▼
Task Scheduler (Task Queue / LocalScheduler)
        │
        ▼
Agent Registry
        │
        ▼
Agent Executor (lifecycle, retry, budgets)
        │
        ▼
Agent Context Resolver
        │
        ├──────────────────────┬──────────────────────┐
        ▼                      ▼                      ▼
Workspace Snapshot     Knowledge Snapshot      Memory Snapshot
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               ▼
                        Knowledge Engine
                               │
                               ▼
                           AI Runtime
                               │
                               ▼
                        Decision Record
                               │
                               ▼
                       Policy Validator
                               │
                               ▼
                       Human Review Gate
                               │
                               ▼
                          Task Result
                               │
                               ▼
                       Platform Event Bus
```
