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
   - **Agent Lifecycle States**: `idle`, `thinking`, `executing`, `waiting` (waiting for other workers or user checks), `reviewRequired`, `completed`, `failed`, `cancelled`.
2. **Immutable `AgentContext`**:
   - Agents never access Workspace or Knowledge Engine APIs directly. Instead, they receive an immutable `AgentContext` containing snapshots, task models, budget limits, cancellation tokens, and memories.
3. **Agent Capability Model**:
   - Instead of hardcoding types, agents expose capabilities (e.g., `Planning`, `Coding`, `Review`, `Testing`, `Documentation`, `Security`) via a `supports(AgentCapability)` validation method.
4. **Task Graph Orchestration**:
   - Workflows are represented as explicit directed task graphs composed of `WorkflowDefinition`, `WorkflowNode`, `WorkflowEdge`, and returning a `WorkflowResult`, executed by a central `AgentScheduler`.
5. **Decoupled Three-Layer Memory**:
   - Memory is split into `AgentMemory` (long-term prompt preferences), `WorkspaceMemory` (project context), and `TaskMemory` (short-term execution state) leveraging the abstract `MemoryProvider` interface.
6. **Unified Decision Records**:
   - Explainability metadata is compiled into a `DecisionRecord` detailing matched resources, confidence levels, cost projections, risk classifications, and recommended actions.
7. **Agent Registry**:
   - Registries support pluggable third-party agent hooks and integrations.
8. **First-class Retry and Budget Mappings**:
   - Budgets (`token_budget.dart`, `cost_budget.dart`, `execution_budget.dart`) and retry strategies (`retry_policy.dart`) are decoupled from execution blocks.

## Directory Structure

```text
lib/core/agent/
├── contracts/
│   ├── agent.dart
│   ├── workflow.dart
│   ├── scheduler.dart
│   ├── task.dart
│   ├── decision_record.dart
│   └── execution_policy.dart
├── context/
│   └── agent_context.dart
├── workflow/
│   ├── workflow_definition.dart
│   ├── workflow_node.dart
│   ├── workflow_edge.dart
│   ├── workflow_result.dart
│   ├── workflow_snapshot.dart
│   ├── workflow_statistics.dart
│   ├── workflow_builder.dart
│   └── workflow_executor.dart
├── scheduler/
│   ├── task_scheduler.dart
│   ├── task_queue.dart
│   └── retry_policy.dart
├── budget/
│   ├── token_budget.dart
│   ├── cost_budget.dart
│   └── execution_budget.dart
├── memory/
│   ├── memory_provider.dart
│   ├── task_memory.dart
│   ├── workspace_memory.dart
│   └── agent_memory.dart
├── statistics/
│   ├── agent_statistics.dart
│   └── scheduler_statistics.dart
├── events/
│   ├── task_queued.dart
│   ├── task_started.dart
│   ├── task_progress.dart
│   ├── task_waiting.dart
│   ├── task_completed.dart
│   ├── task_failed.dart
│   ├── task_cancelled.dart
│   ├── review_requested.dart
│   ├── review_approved.dart
│   └── review_rejected.dart
├── registry/
│   └── agent_registry.dart
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
