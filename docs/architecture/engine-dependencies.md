# Engine Dependencies

This document maps cross-layer engine dependency rules.

## Core Rules
1. **No Circular Dependencies**: Lower layers must not import files from higher layers.
2. **Abstract Boundaries**: Cross-layer interaction occurs exclusively through interfaces defined in `contracts/` directories.
3. **Decoupled Event Models**: Live state updates are transmitted via the platform-wide `EventBus` to prevent tight coupling.
