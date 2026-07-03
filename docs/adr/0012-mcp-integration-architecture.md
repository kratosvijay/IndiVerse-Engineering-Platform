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
2. **Protocol Isolation**:
   - MCP protocol types, transports, serializers, and session models must never propagate beyond the MCP layer. PlatformSDK and lower platform layers remain protocol-agnostic.
3. **Protocol Purity**:
   - The stdout stream is reserved exclusively for MCP protocol frames. Human-readable logs must be written to stderr or a configured logging sink.
4. **MCP Gateway & Serializer Layers**:
   - Introduce an `MCPGateway` translating standard Model Context Protocol messages (tools, resources, prompts) into `PlatformSDK` calls, managing validation, permissions, and serialization via request, response, and error mappers.
5. **Registry & Provider Symmetry**:
   - Implement registries (`ToolRegistry`, `ResourceRegistry`, `PromptRegistry`) backed by provider contracts (`ToolProvider`, `ResourceProvider`, `PromptProvider`) allowing plugins to register dynamic components.
6. **Session Negotiation & Cancellation**:
   - Each connection is tracked via a stateful `McpSession` managing protocol version negotiation, capabilities, and active request cancellation tokens.
7. **Permission Verification Gate**:
   - Enforce permission validation checks (e.g. `Workspace.Read`, `Knowledge.Search`, `Agent.Execute`, `Git.Read`, `Git.Write`) before dispatching tool execution.

## Directory Structure

```text
lib/core/mcp/
├── contracts/
│   ├── transport.dart
│   ├── gateway.dart
│   └── provider.dart
├── server/
│   ├── server.dart
│   ├── router.dart
│   ├── session.dart
│   └── transport.dart
├── gateway/
│   ├── mcp_gateway.dart
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
│   └── permission.dart
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
