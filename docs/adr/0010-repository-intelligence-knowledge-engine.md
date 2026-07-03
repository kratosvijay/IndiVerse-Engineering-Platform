# ADR 0010: Repository Intelligence Knowledge Engine

## Status
Accepted

## Context
For the IndiVerse Developer Platform (IDP) to assist developers with deep repository awareness, it needs a Repository Intelligence and Knowledge Engine. This engine must go beyond simple filesystem listings and support:
1. **Symbol Extraction**: Understanding the logical structure of code (classes, methods, variables, widgets, enums) through pluggable language extractors.
2. **Knowledge Graph Mappings**: Capturing typed dependency relationships (using a `RelationType` enum: `extends`, `implements`, `depends_on`, `calls`, etc.).
3. **Semantic Querying**: Retrieving code regions and ADR references using vector embedding similarities.

To avoid vendor lock-in and keep the architecture flexible, both the embedding generators and the vector storage databases must be completely decoupled.

## Decision
We implement a decoupled, storage-agnostic, and model-agnostic Knowledge Engine (`lib/core/knowledge/`) with the following architectural guarantees:

1. **Repository Intelligence is Provider-Agnostic**:
   - Embedding models must be replaceable without modifying the Knowledge Engine via the `EmbeddingProvider` interface.
2. **Repository Intelligence is Storage-Agnostic**:
   - Vector databases must be replaceable through the `VectorStore` interface (supporting `insert`, `update`, `delete`, `search`, `searchHybrid`, `searchByMetadata`, `clear`, `stats`, `compact`).
3. **Repository Intelligence is Language-Agnostic**:
   - Language-specific parsing must be implemented through pluggable extractors (e.g., `DartExtractor`, `MarkdownExtractor`, `JsonExtractor`).
4. **Repository Intelligence is Event-Driven**:
   - Knowledge indexing, graph updates, cache invalidation, and semantic search lifecycle events (e.g., `KnowledgeIndexStarted`, `DocumentIndexed`, `KnowledgeReady`, `KnowledgeFailed`) are published through the platform Event Bus so other platform components (Workspace Engine, Agent Engine, Studio, Telemetry) remain loosely coupled.
5. **Repository Intelligence is Incremental**:
   - The engine should avoid full repository reindexing whenever possible. Changed documents should be detected through checksums and workspace events, with only affected chunks, embeddings, and graph relationships being recomputed.
6. **Pipeline Separation**:
   - Knowledge Engine acts as an orchestrator for Document, Symbol, Embedding, Graph, Search, and Memory Pipelines.
7. **Public Contracts Isolation**:
   - Separate core contracts into `lib/core/knowledge/contracts/` isolating interfaces (`EmbeddingProvider`, `VectorStore`, `SymbolExtractor`, `Chunker`, `SearchEngine`) from internal implementations.
8. **Relevance Boost & Explanation**:
   - `SemanticSearch` leverages ranking boosts (Graph Boost, Git Boost, Workspace Boost) and produces `SearchResult` objects containing explainability metadata (score, matched symbols, ranking reasons, context sources, provider).

## Consequences
- **Pros**:
  - Developers can swap vector databases (e.g., SQLite to LanceDB/Chroma) and embedding generators seamlessly.
  - Allows semantic workspace search (e.g., "Where is authentication handled?") in under 500 ms.
- **Cons**:
  - Increases abstraction overhead.
