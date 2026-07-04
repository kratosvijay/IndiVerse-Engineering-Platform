# ADR 0016 — Editor Rendering Architecture

## Status
Approved

## Context
As IndiVerse Studio grows into a professional-grade IDE, the editing subsystem requires high rendering performance, clean separation of concerns, and robust cursor/selection mechanics. Storing documents as flat strings and relying on naive list views of rich text lines introduces major performance bottlenecks for large source files (e.g., full-file re-tokenization on every keypress) and tightly couples editor rendering with logical text editing.

To support features like multi-cursor selections, folding, minimaps, diagnostics, inline AI widgets, and git decorations without ongoing refactoring, we require a highly structured editor subsystem.

## Decision
We enforce a decoupled, three-layer architecture for the editor subsystem, separating text management, viewport state, and high-performance rendering. We introduce immutable document snapshots, rendering layers, decoration layers, gutter providers, and viewport caches to enable robust, flicker-free rendering.

### Editor Subsystem Layers

```
  [User Action / Key Event]
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
     [EditorController]
             │
             ▼
      [EditOperation]
             │
             ▼
      [EditorDocument] (List<String> lines, cursor position)
             │
             ▼
     [DocumentSnapshot] (Immutable state frame, revision, lines)
             │
             ▼
    [EditorViewController] (Viewport state, ViewportCache, TokenProvider)
             │
             ▼
    [EditorRenderer] (Custom Painter / RenderObject using PaintContext)
```

1. **EditorDocument (Logical State)**:
   - Owns the text data, stored internally as `List<String> lines` for fast line-level manipulations (insert, delete, duplicate, move line).
   - Manages cursor `Position(line, column)` and selection ranges using a generic `SelectionRange` model.
   - Dispatches mutations exclusively through undo-able/redo-able `EditOperation` instances.

2. **DocumentSnapshot (Immutable State Frame)**:
   - Captures an immutable point-in-time state of the entire document (`revision` and copy of `lines` list).
   - Ensures the renderer operates on a read-only, consistent frame, preventing concurrent modification bugs or layout mismatches during active typing.
   - Visible-line extraction is delegated to the viewport cache, keeping the snapshot decoupled from view/scrolling states.

3. **EditorViewController (Viewport & Presentation State)**:
   - Tracks scroll offsets, visible lines, horizontal/vertical scroll bounds, and horizontal caret placements within an `EditorViewport` metadata record.
   - Coordinates Caret blink animations and resolves text selection rectangles.
   - Emits asynchronous view events via `EditorViewEvent` (e.g., `CursorMoved`, `ViewportChanged`, `SelectionChanged`, `ScrollChanged`).

4. **TokenProvider & ViewportCache**:
   - Decoupled syntax tokenization is handled via a `TokenProvider` abstraction (allowing future LSP/Tree-sitter integrations).
   - Tokenization is incremental (limited to modified lines) and cached per viewport request via `ViewportCache`.

5. **EditorRenderer & Painting Layers**:
   - Renders the editor in layered stages using a `PaintContext` containing the snapshot, viewport, tokens, decorations, gutters, and theme rules from a `ThemeProvider`.
   - Paints in a specific stacked layer sequence:
     1. Background Layer (gutter backdrop, active line highlight)
     2. Selection Layer (text selection overlays)
     3. Syntax/Text Layer (cached token layout runs)
     4. Cursor Layer (blinking caret indicator)
     5. Overlay Layer (folding placeholders, brackets)

### Customization & Extension Interfaces

1. **GutterProvider**:
   - Gutter components (line numbers, fold markers, breakpoint nodes, git status changes) are abstracted behind a unified `GutterProvider` interface. The renderer queries these providers sequentially.

2. **DecorationProvider**:
   - Highlight markers (bracket match highlights, selection highlight blocks, search results, inline git diff indicators) are abstracted behind a `DecorationProvider` interface. The renderer queries registered decoration providers and paints them dynamically.

3. **LanguageEditingStrategy**:
   - Smart features like comment toggling (`toggleComment()`), outdenting/indenting (`autoIndent()`), and bracket closing (`autoCloseBracket()`) are decoupled into a generic `LanguageEditingStrategy` interface, concrete implementations of which are selected dynamically based on document file extensions.

4. **Local Bracket Scanning**:
   - Bracket matching and scoping checks are restricted to the local context window around the cursor (e.g. ±1000 characters or within the visible `EditorViewport`) to keep scans fast.
