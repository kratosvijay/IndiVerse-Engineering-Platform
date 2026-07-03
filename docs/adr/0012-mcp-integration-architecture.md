# ADR 0012: MCP Integration Architecture

## Status
Proposed

## Context
With the core platform cockpit (Studio UI v0.8.0) and backend engines completed, the platform now needs to expose its capabilities (semantic search, code workspace discovery, multi-agent runs) to external developer environments like Claude Desktop, VS Code, and other editors. 

To ensure loose coupling, compliance with the Engineering Constitution, and to prevent architectural drift, we need to design a native Model Context Protocol (MCP) server layer.

## Decision
We implement a decoupled, registry-driven, and session-based MCP Server integration (`lib/core/mcp/`) conforming to the following structural guarantees:

1. **Platform SDK Integration Boundary**:
   - The MCP server never interacts with lower-level core engines (Workspace, Knowledge, Agent, Runtime) directly. It must communicate exclusively through the `PlatformSDK` facade APIs.
2. **MCP Gateway Pattern**:
   - Introduce an `MCPGateway` translating standard Model Context Protocol messages (tools, resources, prompts) into `PlatformSDK` calls, managing validation, permissions, and serialization.
3. **Pluggable Registries**:
   - Implement `ToolRegistry`, `ResourceRegistry`, and `PromptRegistry` so that new tools, files, or agent capabilities can be dynamically registered without altering the MCP transport core.
4. **Session Manager**:
   - Each connection is tracked via a stateful `McpSession` managing protocol versions, capabilities, and workspace scopes.
5. **Transport Abstraction**:
   - Expose an abstract `McpTransport` interface supporting stdio-based streams (default) with future-proofing for HTTP/WebSocket connections.

## Directory Structure

```text
lib/core/mcp/
├── contracts/
│   ├── transport.dart
│   └── gateway.dart
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
└── models/
    ├── mcp_tool.dart
    ├── mcp_resource.dart
    └── mcp_prompt.dart
```

## Consequences
- **Pros**:
  - Exposes all core repository intelligence and agent workflows to any MCP-compliant LLM client.
  - Maintains strict architectural layering boundaries by using the `PlatformSDK` facade.
- **Cons**:
  - Incremental transport mapping and JSON-RPC message translation overhead.
