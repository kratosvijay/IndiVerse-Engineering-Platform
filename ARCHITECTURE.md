# IndiVerse Developer Platform (IDP) - High-Level Architecture

## Platform Layers
```text
Applications / IDEs (VS Code, JetBrains plugins)
                      │
                      ▼
            Studio Dashboard (v0.8)
                      │
                      ▼
             Agent Engine (v0.7)
                      │
                      ▼
           Knowledge Engine (v0.6)
                      │
                      ▼
           Workspace Engine (v0.5)
                      │
                      ▼
             Plugin SDK & Runtime
                      │
                      ▼
      Provider Adapters (Gemini, Ollama)
```

## Architecture Stability Guarantees
The following APIs are considered stable once v1.0 GA is released:
- **Plugin SDK**
- **AI Runtime**
- **Provider Interface**
- **Context API**
- **Event Bus**
- **Workspace API**
- **Knowledge API**

Any breaking change to these stable components requires:
1. A new ADR (Architecture Decision Record)
2. A major version bump (e.g. `1.0.0` to `2.0.0`)
3. A complete migration guide for third-party plugin authors
