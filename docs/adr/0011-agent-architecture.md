# ADR 0011: Agent Architecture

## Status
Accepted

## Context
With the workspace and repository intelligence (Knowledge Engine) layers completed, the platform now requires an orchestration layer to coordinate multi-agent development tasks (e.g. planning, code writing, review, testing). 

To ensure loose coupling, robustness, and compliance with the Engineering Constitution, we need a disciplined Agent Architecture.

## Decision
We implement a decoupled, task-driven, and event-based Agent Engine (`lib/core/agent/`) conforming to the following structural guarantees:

1. **Orchestrator and Executor Separation**:
   - **Workflows** own task graph routing and orchestration.
   - **AgentExecutor** handles lifecycle transitions, retries, timeout enforcement, telemetry, cancellations, and budget enforcement.
   - **Agents** remain stateless executors implementing only prompt business logic.
2. **Immutable `AgentContext` and `ContextResolver`**:
   - Context is compiled by an `AgentContextResolver` aggregating snapshots from Workspace, Knowledge, Memory, and Plugins.
3. **Agent Capability Matrix & Manifest**:
   - Expose agent capabilities (`Planning`, `Coding`, `Review`, `Testing`, `Documentation`, `Security`) via an `AgentCapabilityMatrix`. Each agent exposes an `AgentManifest` metadata definition (version, capabilities, permissions, estimated limits).
4. **Task Graph Serialization**:
   - Workflows are represented as explicit directed task graphs composed of `WorkflowDefinition`, `WorkflowNode`, `WorkflowEdge`, and returning a `WorkflowResult`. Workflows serialize to JSON via `WorkflowSnapshot` for Studio display.
5. **Decoupled Three-Layer Memory**:
   - Memory is split into `AgentMemory`, `WorkspaceMemory`, and `TaskMemory` caching leveraging the abstract `MemoryProvider` interface.
6. **Policy Validator & Review Gates**:
   - Prior to human review, a `PolicyValidator` audits execution budget limits, dangerous filesystem writes, and git mutations.
   - Execution gates enforce: `Automatic` $\rightarrow$ `Policy Review` $\rightarrow$ `Human Review` $\rightarrow$ `Execution`.
7. **Execution Policies**:
   - Core policies include: `Safe`, `Interactive`, `ApprovalRequired`, `Autonomous`.
8. **Pluggable Scheduler Schedulers**:
   - Define a generic `Scheduler` contract with implementations for `LocalScheduler` and potential future `DistributedScheduler` workers.

## Directory Structure

```text
lib/core/agent/
├── contracts/
│   ├── agent.dart
│   ├── workflow.dart
│   ├── scheduler.dart
│   ├── task.dart
│   ├── executor.dart
│   ├── decision_record.dart
│   └── execution_policy.dart
├── context/
│   ├── agent_context.dart
│   └── context_resolver.dart
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
├── executor/
│   ├── agent_executor.dart
│   └── policy_validator.dart
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
