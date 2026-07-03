# ADR 0006: AI Runtime Architecture

- **Status**: Accepted
- **Date**: 2026-07-03
- **Author**: Platform Governance Board

## Context & Problem Statement
Integrating raw LLM SDK endpoints into application logic creates tight coupling. We need an extensible execution engine to govern multi-agent requests, middleware, event dispatching, and usage tracking.

## Decision Drivers
- Provider-agnostic requests (`AIRequest`) and normalized responses (`AIResponse`).
- Event-driven telemetry (decoupled tracing, token counting, cost tracking).
- Extensible pipeline utilizing chainable middleware interceptors.
- Capacity-based model routing (matching tasks to specific reasoning/streaming capabilities).

## Decision Outcome
Implement the **IndiVerse AI Runtime Architecture**:
- **Contracts Layer**: Interfaces for `AIProvider`, `RuntimeCore`, and configurations.
- **Middleware Pipeline**: Request pre-processing (validation, auth) and post-processing (retry, backoff).
- **Event Bus**: Event publishing for tracing (`RuntimeStarted`, `RuntimeCompleted`, `RetryAttempted`, `BudgetExceeded`).
- **Telemetry trackers**: Listen to event bus to calculate input, output, reasoning tokens, and financial costs.

## Consequences
- **Positive**: Complete loose coupling of telemetry, retry logic, and platform loggers. AI providers can be swapped transparently.
- **Negative**: Indirection due to abstract dispatch handlers and middleware builders.
