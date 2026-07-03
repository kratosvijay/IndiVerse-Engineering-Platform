# ADR 0011: Agent Architecture

## Status
Proposed

## Context
With the workspace and repository intelligence (Knowledge Engine) layers completed, the platform now requires an orchestration layer to coordinate multi-agent development tasks (e.g. planning, code writing, review, testing). 

To ensure loose coupling, robustness, and compliance with the Engineering Constitution, we need a disciplined Agent Architecture.

## Decision
We implement a decoupled, task-driven, and event-based Agent Engine (`lib/core/agent/`) conforming to the following structural guarantees:

1. **Micro-Agents with Single Concerns**:
   - Instead of monolithic agents, we implement specialized micro-agents: `PlannerAgent`, `DeveloperAgent`, `ReviewerAgent`, `TesterAgent`, `SecurityAgent`, `DocumentationAgent`.
2. **Standardized Agent Lifecycle**:
   - States: `idle` $\rightarrow$ `thinking` $\rightarrow$ `executing` $\rightarrow$ `reviewRequired` $\rightarrow$ `completed` $\rightarrow$ `failed` $\rightarrow$ `cancelled`.
3. **Task & Budget Allocation**:
   - Every task has an explicit `TokenBudget` and a `CostLimit`. Task execution handles failures, timeouts, and cancellations gracefully.
4. **Platform Event Bus Integration**:
   - Agents communicate implicitly through events on the Platform Event Bus, broadcasting status changes (e.g. `TaskStarted`, `TaskCompleted`, `ReviewRequested`).
5. **Decoupled Agent Memory**:
   - Expose workspace-local and agent-specific memory caching (excluding raw embeddings) for temporal state management.
6. **Mandatory Human Review**:
   - Destructive operations (such as code updates or commits) require human approval verification gates.

## Consequences
- **Pros**:
  - Modular agents can be independently debugged and replaced.
  - Aligns agent actions with the "Explainable AI" constitution rule.
- **Cons**:
  - Introduces multi-agent synchronization and routing overhead.
