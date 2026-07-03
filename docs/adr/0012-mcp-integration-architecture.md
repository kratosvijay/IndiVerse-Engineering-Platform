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
3. **Protocol Isolation**:
   - MCP protocol types, transports, serializers, and session models must never propagate beyond the MCP layer. PlatformSDK and lower platform layers remain protocol-agnostic.
4. **Protocol Purity**:
   - The stdout stream is reserved exclusively for MCP protocol frames. Human-readable logs must be written to stderr or a configured logging sink.
5. **Request Middleware Pipeline**:
   - Setup a request middleware pipeline executing tasks sequentially: `Protocol Validation` $\rightarrow$ `Authentication` $\rightarrow$ `Permission Validation` $\rightarrow$ `Rate Limiting` $\rightarrow$ `Dispatch` $\rightarrow$ `Serialization`.
6. **Authorization Service & Context Wrappers**:
   - Decouple permission checks to an independent `AuthorizationService`.
   - Provide dynamic execution data (session, workspace, cancellation tokens) inside a unified `ToolExecutionContext` wrapper.
7. **Tool Manifest & Versioned Registries**:
   - Map available actions through a `ToolManifest` configuration definition. Track resources and prompts within versioned registries.
8. **Registry & Provider Symmetry**:
   - Implement registries (`ToolRegistry`, `ResourceRegistry`, `PromptRegistry`) backed by provider contracts (`ToolProvider`, `ResourceProvider`, `PromptProvider`) supporting streamable chunks (`Stream<ResourceChunk>`).
9. **Session Negotiation & Cancellation**:
   - Each connection is tracked via a stateful `McpSession` managing protocol version/capability negotiation, and active request cancellation tokens.
10. **Pluggable Transports**:
    - Support multiple transport layers: `StdioTransport`, `HttpTransport`, `WebSocketTransport`, `NamedPipeTransport`.

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
│   └── transport.dart
├── gateway/
│   ├── mcp_gateway.dart
│   ├── authorization_service.dart
│   ├── tool_dispatcher.dart
│   ├── resource_dispatcher.dart
│   └── prompt_dispatcher.dart
├── registry/
│   ├── tool_registry.dart
│   ├── resource_registry.dart
│   └── prompt_registry.dart
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
