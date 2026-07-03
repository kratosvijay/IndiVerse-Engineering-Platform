# Knowledge Engine Flow

This document details the pipeline execution flow within the Repository Intelligence Knowledge Engine.

## Linear Flow

```text
Workspace Watcher / Reindex Scheduler
                 │
                 ▼
         Document Pipeline (document loader)
                 │
                 ▼
          Chunk Pipeline (chunker algorithm)
                 │
                 ▼
         Language Extractors (Dart, Markdown, JSON)
                 │
                 ▼
         Embedding Pipeline (model embedding vector)
                 │
                 ▼
         Vector Store / Knowledge Graph
                 │
                 ▼
         Ranking Engine (graph/git boosts)
                 │
                 ▼
          Semantic Search (query builder)
                 │
                 ▼
         Knowledge Engine Orchestrator
```

## Internal Orchestration Flow

```text
Workspace Engine
        │
        ▼
   IndexRequest
        │
        ▼
Indexing Pipeline
        │
        ├───────────────┐
        ▼               ▼
Document Pipeline   Symbol Pipeline
        │               │
        └──────┬────────┘
               ▼
      Embedding Pipeline
               │
        ┌──────┴───────┐
        ▼              ▼
  Vector Store    Knowledge Graph
        │              │
        └──────┬───────┘
               ▼
       Ranking Engine
               │
               ▼
      Semantic Search
               │
               ▼
      Knowledge Engine
```

