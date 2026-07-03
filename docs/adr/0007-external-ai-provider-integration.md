# ADR 0007: External AI Provider Integration

## Status
Accepted

## Context
As defined in ADR 0005, the AI Runtime must remain vendor-neutral. We need to integrate external AI capabilities (beginning with Google's Gemini API) without leaking provider-specific protocols, types, or models into the core runtime engine.

## Decision
We establish the **Adapter Pattern** for external AI provider integrations. Every external model service is isolated into its own provider package module under `lib/core/providers/` and conforms to the following rules:

1. **Explicit Separation of Concerns**:
   - `gemini_adapter.dart` implements `AIProvider` and manages high-level lifecycle methods.
   - `gemini_api_client.dart` encapsulates raw HTTP/HTTPS protocol requests and network handshakes.
   - `gemini_request_mapper.dart` and `gemini_response_mapper.dart` translate data schemas to/from internal core types.
2. **Health Check & Fault Isolation**:
   - Every provider adapter exposes its current `ProviderHealth` (e.g. `healthy`, `degraded`, `unavailable`, `rateLimited`).
   - Network errors are mapped to our unified exceptions hierarchy (`RateLimitException` with retry hints, `AuthenticationException`, etc.) instead of leaking raw socket errors or HTTP codes.
3. **Capabilities Matrix**:
   - Providers register capability metadata (text, vision, streaming, tools) in a `ProviderManifest` to enable capabilities-based routing in the `ModelRegistry`.

## Consequences
- **Pros**:
  - Direct, modular swapping: adding a new provider (e.g., Anthropic, OpenAI) requires only implementing a new provider package without code changes in the runtime.
  - Highly robust: rate limit handling, safety maps, and model metadata bounds are self-contained.
- **Cons**:
  - Small overhead in implementing request/response serializers for each new provider.
