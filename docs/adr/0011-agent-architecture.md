# ADR 0011: Agent Architecture

## Status
Accepted

## Context
With the workspace and repository intelligence (Knowledge Engine) layers completed, the platform now requires an orchestration layer to coordinate multi-agent development tasks (e.g. planning, code writing, review, testing). 

To ensure loose coupling, robustness, and compliance with the Engineering Constitution, we need a disciplined Agent Architecture.

## Decision
We implement a decoupled, task-driven, and event-based Agent Engine (`lib/core/agent/`) conforming to the following structural guarantees:

1. **Orchestrator and Executor Separation**:
   - **Workflows** compile into an `ExecutionPlan` containing ordered tasks, dependencies, retry strategies, and budgets.
   - **AgentExecutor** executes individual micro-agents inside a stateful `AgentSession` tracking telemetry and decision history.
   - **Agents** remain stateless executors.
2. **Immutable `AgentContext` and `ContextSource`**:
   - Context is resolved by a `AgentContextResolver` gathering data from explicit `ContextSource` targets (Workspace, Knowledge, Memory, Git, Plugin, MCP, User Input).
3. **Agent Capability Matrix & Manifest**:
   - Expose agent capabilities via an `AgentCapabilityMatrix` and metadata versioning fields inside `AgentManifest` (matching PluginManifest layout).
4. **Workflow validation**:
   - A `WorkflowValidator` checks for dependency cycles, missing nodes, or impossible branches before execution begins.
5. **Decoupled Three-Layer Memory**:
   - Memory is split into `AgentMemory`, `WorkspaceMemory`, and `TaskMemory` caching leveraging the abstract `MemoryProvider` interface.
6. **Policy Validator & Review Gates**:
   - Prior to human review, a `PolicyValidator` delegates check constraints to decoupled policies: `SecurityPolicy`, `FilesystemPolicy`, `GitPolicy`, `BudgetPolicy`, `PluginPolicy`.
   - Execution gates enforce: `Automatic` $\rightarrow$ `Policy Review` $\rightarrow$ `Human Review` $\rightarrow$ `Execution`.
7. **Execution Results**:
   - Return specialized result subclasses: `ExecutionResult`, `ReviewResult`, `FailureResult`, `CancelledResult`.
8. **Pluggable Schedulers**:
   - Define a generic `Scheduler` contract under `lib/core/agent/contracts/scheduler.dart` implemented locally via `LocalScheduler`.

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
│   ├── execution_policy.dart
│   └── memory_provider.dart
├── context/
│   ├── agent_context.dart
│   ├── context_source.dart
│   └── context_resolver.dart
├── workflow/
│   ├── workflow_definition.dart
│   ├── workflow_node.dart
│   ├── workflow_edge.dart
│   ├── workflow_result.dart
│   ├── workflow_snapshot.dart
│   ├── workflow_statistics.dart
│   ├── workflow_builder.dart
│   ├── workflow_validator.dart
│   └── workflow_executor.dart
├── scheduler/
│   ├── local_scheduler.dart
│   ├── task_queue.dart
│   ├── execution_plan.dart
│   └── retry_policy.dart
├── executor/
│   ├── agent_executor.dart
│   ├── agent_session.dart
│   └── policy_validator.dart
├── policies/
│   ├── security_policy.dart
│   ├── filesystem_policy.dart
│   ├── git_policy.dart
│   ├── budget_policy.dart
│   └── plugin_policy.dart
├── budget/
│   ├── token_budget.dart
│   ├── cost_budget.dart
│   └── execution_budget.dart
├── memory/
│   ├── task_memory.dart
│   ├── workspace_memory.dart
│   └── agent_memory.dart
├── statistics/
│   ├── agent_statistics.dart
│   ├── workflow_statistics.dart
│   └── scheduler_statistics.dart
├── events/
│   ├── workflow_events.dart
│   ├── task_events.dart
│   ├── review_events.dart
│   ├── scheduler_events.dart
│   └── memory_events.dart
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
