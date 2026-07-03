# ADR 0011: Agent Architecture

## Status
Accepted

## Context
With the workspace and repository intelligence (Knowledge Engine) layers completed, the platform now requires an orchestration layer to coordinate multi-agent development tasks (e.g. planning, code writing, review, testing). 

To ensure loose coupling, robustness, and compliance with the Engineering Constitution, we need a disciplined Agent Architecture.

## Decision
We implement a decoupled, task-driven, and event-based Agent Engine (`lib/core/agent/`) conforming to the following structural guarantees:

1. **Separation of Workflow and Agent Execution**:
   - **Workflows** own task graph routing and orchestration.
   - **Agents** own execution and do not spawn other agents recursively.
2. **Immutable `AgentContext`**:
   - Agents never access Workspace or Knowledge Engine APIs directly. Instead, they receive an immutable `AgentContext` containing snapshots, task models, budget limits, cancellation tokens, and memories.
3. **Agent Capability Model**:
   - Instead of hardcoding types, agents expose capabilities (e.g., `Planning`, `Coding`, `Review`, `Testing`, `Documentation`, `Security`) via a `supports(AgentCapability)` validation method.
4. **Task Graph Orchestration**:
   - Workflows are represented as directed task graphs executed by a central `AgentScheduler`.
5. **Decoupled Three-Layer Memory**:
   - Memory is split into `AgentMemory` (long-term prompt preferences), `WorkspaceMemory` (project context), and `TaskMemory` (short-term execution state).
6. **Unified Decision Records**:
   - Explainability metadata is compiled into a `DecisionRecord` detailing matched resources, confidence levels, cost projections, risk classifications, and recommended actions.
7. **Agent Registry**:
   - Registries support pluggable third-party agent hooks and integrations.

## Directory Structure

```text
lib/core/agent/
├── contracts/
│   ├── agent.dart
│   ├── workflow.dart
│   └── scheduler.dart
├── context/
│   ├── agent_context.dart
│   └── task_context.dart
├── lifecycle/
│   ├── agent_state.dart
│   └── lifecycle.dart
├── registry/
│   └── agent_registry.dart
├── scheduler/
│   └── task_scheduler.dart
├── workflow/
│   ├── workflow.dart
│   ├── workflow_builder.dart
│   └── workflow_executor.dart
├── memory/
│   ├── task_memory.dart
│   ├── workspace_memory.dart
│   └── agent_memory.dart
├── events/
│   ├── task_started.dart
│   ├── task_completed.dart
│   └── review_requested.dart
└── agents/
    ├── planner/
    ├── developer/
    ├── reviewer/
    ├── tester/
    ├── documentation/
    └── security/
```

## Consequences
- **Pros**:
  - Modular agents can be independently debugged and replaced.
  - Aligns agent actions with the "Explainable AI" constitution rule.
  - Prepares the platform for parallel, distributed execution.
- **Cons**:
  - Introduces multi-agent synchronization and routing overhead.
