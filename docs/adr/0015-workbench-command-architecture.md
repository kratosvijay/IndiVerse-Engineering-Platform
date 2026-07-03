# ADR 0015 — Workbench Command Architecture

## Status
Approved

## Context
As IndiVerse Studio grows from a code browser into a professional-grade IDE workbench, we require a scalable, decoupled communication pattern for executing user actions. User actions can originate from multiple sources:
1. Keyboard Shortcuts
2. Command Palette (Cmd+Shift+P)
3. UI Widgets (toolbar buttons, menu items, context menus)
4. Built-in Agent Engines (AI Actions)
5. External Plugins

Directly coupling these triggers to widget states or deep backend services leads to duplicated logic, inconsistent behavior, and makes extensibility difficult.

## Decision
We enforce a unified Command Architecture where all user actions must execute through a centralized `CommandRegistry` via the `WorkbenchApi` facade.

### Command Execution Sequence
```
[User Trigger (Key / Menu / AI / Plugin)]
                   │
                   ▼
       [KeyboardShortcutManager]
                   │
                   ▼
           [CommandRegistry]
                   │
                   ▼
            [WorkbenchApi]
                   │
                   ▼
             [EditorApi] -> [DocumentService] / [StudioState]
```

### Constraints & Rules
1. **No Direct Inter-widget Calls**: UI widgets must not directly invoke actions on other widgets. They must execute a registered command constant identifier from the strongly-typed `WorkbenchCommands` schema (e.g., `WorkbenchCommands.fileOpen`).
2. **Central Registry**: All command definitions (id, name, shortcut, execution handler) are registered in the `CommandRegistry` on startup.
3. **Decoupled Keybindings**: KeyboardShortcutManager intercepts raw key events, resolves them to registered command IDs, and dispatches them to the `CommandRegistry`.
4. **API-Backed Commands**: Registered command handlers delegate execution directly to the versioned `WorkbenchApi` facade.
5. **Command Dispatcher Middleware**: Execution triggers go through the `CommandDispatcher` which supports pipeline middleware hooks for logging, permissions, analytics, and transaction registration before executing the underlying handler.

## Conformance & Extensibility
This architecture guarantees that any future capabilities (such as AI agents or third-party plugins) can invoke the exact same commands programmatically as a human developer using keyboard shortcuts.

