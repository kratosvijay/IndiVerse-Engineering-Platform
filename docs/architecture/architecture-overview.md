# Architecture Overview

This document provides a high-level overview of the IndiVerse Developer Platform (IDP) architecture.

## Platform Layers

```text
       Applications / IDE Clients (Studio)
                       │
                       ▼
          Workflow & Agent Engine (v0.7)
                       │
                       ▼
            Knowledge Engine (v0.6)
                       │
                       ▼
            Workspace Engine (v0.5)
                       │
                       ▼
         Plugin Platform & Sandbox (v0.4)
                       │
                       ▼
               AI Runtime (v0.2)
                       │
                       ▼
            Provider Adapters (v0.3)
```

The layers follow a strict topological order ensuring lower-level components are entirely unaware of higher-level orchestrations.
