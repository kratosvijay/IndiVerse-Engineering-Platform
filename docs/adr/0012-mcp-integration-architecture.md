# ADR 0012: MCP Integration Architecture

## Status
Accepted

## Context
With the core platform cockpit (Studio UI v0.8.0) and backend engines completed, the platform now needs to expose its capabilities (semantic search, code workspace discovery, multi-agent runs) to external developer environments like Claude Desktop, VS Code, and other editors. 

To ensure loose coupling, compliance with the Engineering Constitution, and to prevent architectural drift, we need to design a native Model Context Protocol (MCP) server layer.

## Decision
We implement a decoupled, registry-driven, and session-based MCP Server integration (`lib/core/mcp/`) conforming to the following structural guarantees:

1. **Platform SDK Integration Boundary**:
   - The MCP server never interacts with lower-level core engines directly. It must communicate exclusively through the `PlatformSDK` facade APIs.
2. **Platform Capability Isolation**:
   - MCP tools must expose only Platform SDK capabilities. They must never reveal internal engine implementations, object graphs, or private runtime state.
3. **Deterministic Tool Execution**:
   - For identical request payloads, tool execution should be deterministic unless explicitly documented otherwise. Any non-deterministic behavior (such as AI generation or external network access) must be declared in the corresponding ToolManifest.
4. **Protocol Isolation**:
   - MCP protocol types, transports, serializers, and session models must never propagate beyond the MCP layer. PlatformSDK and lower platform layers remain protocol-agnostic.
5. **Protocol Purity**:
   - The stdout stream is reserved exclusively for MCP protocol frames. Human-readable logs must be written to stderr or a configured logging sink.
6. **Middleware Chain**:
   - Support a standard `MiddlewareChain` where each middleware implements `handle(request, next)` to pipeline: `Validation` $\rightarrow$ `Authentication` $\rightarrow$ `Permission` $\rightarrow$ `Rate Limiting` $\rightarrow$ `Dispatch` $\rightarrow$ `Serialization`.
7. **Session, Request, and Tool Contexts**:
   - Separate scopes cleanly into `SessionContext`, `RequestContext`, and `ToolExecutionContext`.
8. **Tool Manifest & Versioned Registries**:
   - Expose metadata fields inside `ToolManifest` (including `minimumProtocol`, `maximumProtocol`, and category classifications: Workspace, Knowledge, Agent, Git, Metrics, Diagnostics, Plugin).
9. **Registry & Provider Symmetry**:
   - Implement registries backed by providers supporting streamable chunks (`Stream<ResourceChunk>`).
10. **Session Negotiation & Cancellation**:
    - Each connection is tracked via stateful `McpSession` managing protocol version/capability negotiation (tools, resources, prompts, sampling, logging, progress, streaming), and cancellations via a centralized `CancellationRegistry`.
11. **Transport Factory**:
    - Build a `TransportFactory` to dynamically compile transport layers: `StdioTransport`, `HttpTransport`, `WebSocketTransport`, `NamedPipeTransport`.
12. **Error Taxonomy**:
    - Standardize JSON-RPC mapping exceptions: `ProtocolError`, `PermissionError`, `ValidationError`, `ToolError`, `RuntimeError`, `InternalError`.

## Directory Structure

```text
lib/core/mcp/
├── contracts/
│   ├── transport.dart
│   ├── gateway.dart
│   ├── provider.dart
│   └── middleware.dart
├── server/
│   ├── server.dart
│   ├── router.dart
│   ├── session.dart
│   ├── transport.dart
│   └── transport_factory.dart
├── gateway/
│   ├── mcp_gateway.dart
│   ├── authorization_service.dart
│   ├── tool_dispatcher.dart
│   ├── resource_dispatcher.dart
│   └── prompt_dispatcher.dart
├── registry/
│   ├── tool_registry.dart
│   ├── resource_registry.dart
│   ├── prompt_registry.dart
│   └── cancellation_registry.dart
├── providers/
│   ├── tool_provider.dart
│   ├── resource_provider.dart
│   └── prompt_provider.dart
├── serialization/
│   ├── request_mapper.dart
│   ├── response_mapper.dart
│   └── error_mapper.dart
├── models/
│   ├── mcp_tool.dart
│   ├── mcp_resource.dart
│   ├── mcp_prompt.dart
│   ├── permission.dart
│   ├── tool_manifest.dart
│   ├── session_context.dart
│   ├── request_context.dart
│   └── tool_execution_context.dart
├── events/
│   └── mcp_events.dart
└── statistics/
    └── mcp_statistics.dart
```

## Consequences
- **Pros**:
  - Exposes all core repository intelligence and agent workflows to any MCP-compliant LLM client.
  - Maintains strict architectural layering boundaries by using the `PlatformSDK` facade.
- **Cons**:
  - Incremental transport mapping and JSON-RPC message translation overhead.
