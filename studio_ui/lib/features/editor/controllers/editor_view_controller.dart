import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../models/editor_document.dart';
import '../highlighting/abstract_highlighter.dart';

class EditorViewport {
  final int firstVisibleLine;
  final int lastVisibleLine;
  final double horizontalOffset;
  final double verticalOffset;
  final double viewportWidth;
  final double viewportHeight;

  const EditorViewport({
    required this.firstVisibleLine,
    required this.lastVisibleLine,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.viewportWidth,
    required this.viewportHeight,
  });
}

class ViewportCache {
  final Map<int, InlineSpan> _tokenCache = {};

  InlineSpan? get(int lineIndex) {
    return _tokenCache[lineIndex];
  }

  void put(int lineIndex, InlineSpan tokens) {
    _tokenCache[lineIndex] = tokens;
  }

  void invalidateLine(int lineIndex) {
    _tokenCache.remove(lineIndex);
  }

  void clear() {
    _tokenCache.clear();
  }
}

abstract class TokenProvider {
  InlineSpan tokenizeLine(BuildContext context, String lineText, int lineIndex);
}

class HighlighterTokenProvider implements TokenProvider {
  final SyntaxHighlighter highlighter;

  HighlighterTokenProvider(this.highlighter);

  @override
  InlineSpan tokenizeLine(
    BuildContext context,
    String lineText,
    int lineIndex,
  ) {
    return highlighter.highlight(context, lineText);
  }
}

abstract class EditorViewEvent {}

class CursorMovedEvent extends EditorViewEvent {
  final Position cursor;
  CursorMovedEvent(this.cursor);
}

class ViewportChangedEvent extends EditorViewEvent {
  final EditorViewport viewport;
  ViewportChangedEvent(this.viewport);
}

class SelectionChangedEvent extends EditorViewEvent {
  final SelectionRange? selection;
  SelectionChangedEvent(this.selection);
}

class ScrollChangedEvent extends EditorViewEvent {
  final double scrollOffset;
  ScrollChangedEvent(this.scrollOffset);
}

class EditorViewController extends ChangeNotifier {
  final EditorDocument document;
  final TokenProvider tokenProvider;
  final ViewportCache viewportCache = ViewportCache();
  int _lastRevision = -1;

  final List<int> _visualToActual = [];
  final Map<int, int> _actualToVisual = {};

  EditorViewport viewport = const EditorViewport(
    firstVisibleLine: 1,
    lastVisibleLine: 1,
    horizontalOffset: 0.0,
    verticalOffset: 0.0,
    viewportWidth: 0.0,
    viewportHeight: 0.0,
  );

  final StreamController<EditorViewEvent> _eventController =
      StreamController<EditorViewEvent>.broadcast();
  Stream<EditorViewEvent> get events => _eventController.stream;

  List<int> get visualToActual => List.unmodifiable(_visualToActual);
  int get visualLineCount => _visualToActual.length;

  int actualToVisualLine(int actualLine) {
    return _actualToVisual[actualLine] ?? (actualLine - 1);
  }

  int visualToActualLine(int visualIndex) {
    if (visualIndex < 0 || visualIndex >= _visualToActual.length) return 1;
    return _visualToActual[visualIndex];
  }

  EditorViewController({required this.document, required this.tokenProvider}) {
    document.addListener(_onDocumentChanged);
    _lastRevision = document.version.localRevision;
    _rebuildLineMappings();
  }

  @override
  void dispose() {
    document.removeListener(_onDocumentChanged);
    _eventController.close();
    super.dispose();
  }

  void _rebuildLineMappings() {
    _visualToActual.clear();
    _actualToVisual.clear();

    int currentLine = 1;
    int visualIndex = 0;
    while (currentLine <= document.lineCount) {
      _visualToActual.add(currentLine);
      _actualToVisual[currentLine] = visualIndex;

      final collapsedRegion = document.foldingLookup[currentLine];
      if (collapsedRegion != null && collapsedRegion.collapsed) {
        currentLine = collapsedRegion.endLine + 1;
      } else {
        currentLine++;
      }
      visualIndex++;
    }
  }

  void _onDocumentChanged() {
    if (document.version.localRevision != _lastRevision) {
      viewportCache.clear();
      _lastRevision = document.version.localRevision;
    }
    _rebuildLineMappings();
    _eventController.add(CursorMovedEvent(document.cursor));
    if (document.selection != null) {
      _eventController.add(SelectionChangedEvent(document.selection));
    }
    notifyListeners();
  }

  void updateViewport(EditorViewport newViewport) {
    if (viewport.firstVisibleLine != newViewport.firstVisibleLine ||
        viewport.lastVisibleLine != newViewport.lastVisibleLine ||
        viewport.horizontalOffset != newViewport.horizontalOffset ||
        viewport.verticalOffset != newViewport.verticalOffset) {
      viewport = newViewport;
      _eventController.add(ViewportChangedEvent(viewport));
      notifyListeners();
    }
  }

  void updateScroll(double offset) {
    _eventController.add(ScrollChangedEvent(offset));
  }

  InlineSpan getLineTokens(BuildContext context, int lineIndex) {
    final cached = viewportCache.get(lineIndex);
    if (cached != null) return cached;

    final lineText = lineIndex <= document.lineCount
        ? document.lines[lineIndex - 1]
        : '';
    final tokens = tokenProvider.tokenizeLine(context, lineText, lineIndex);
    viewportCache.put(lineIndex, tokens);
    return tokens;
  }

  void refresh() {
    notifyListeners();
  }
}
