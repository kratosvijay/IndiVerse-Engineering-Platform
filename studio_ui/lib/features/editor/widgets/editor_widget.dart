import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/studio_state.dart';
import '../../../core/services/workbench_providers.dart';
import '../../../core/services/workbench_commands.dart';
import '../../../models/ids.dart';
import '../../../models/editor_document.dart';
import '../../../models/workspace_events.dart';
import '../../../core/services/overlay_manager.dart';
import '../../../models/language_intelligence_models.dart';
import '../../../models/edit_operation.dart';
import '../../../../models/completion_session.dart';
import 'completion_overlay_widget.dart';
import '../../editor/controllers/signature_help_controller.dart';
import '../../editor/controllers/code_action_controller.dart';
import 'signature_help_overlay_widget.dart';
import 'code_action_lightbulb.dart';
import 'code_action_overlay_widget.dart';
import 'dart:async';
import '../../../core/services/semantic_tokens_token_provider.dart';
import '../../../core/services/keyboard_shortcut_manager.dart';
import '../highlighting/abstract_highlighter.dart';
import '../highlighting/dart_highlighter.dart';
import '../highlighting/json_highlighter.dart';
import '../highlighting/yaml_highlighter.dart';
import '../highlighting/markdown_highlighter.dart';
import '../highlighting/text_highlighter.dart';
import '../decorations/diagnostics_decoration_provider.dart';
import '../gutters/diagnostics_gutter_provider.dart';
import 'breadcrumb_symbols_widget.dart';
import 'references_panel.dart';
import 'find_overlay_widget.dart';
import '../../problems/widgets/problems_panel.dart';
import '../controllers/editor_view_controller.dart';
import '../../../models/inline_ai_models.dart';
import 'inline_ai_overlay_widget.dart';
import 'editor_renderer.dart';
import 'minimap_widget.dart';

class EditorWidget extends StatefulWidget {
  final StudioState state;

  const EditorWidget({super.key, required this.state});

  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _symbolController = TextEditingController();
  List<Map<String, dynamic>> _references = [];
  String _symbolQuery = '';

  // Find properties
  bool _showFind = false;
  List<int> _matchLineIndices = [];
  int _currentMatchIdx = 0;

  // Minimap properties
  bool _showMinimap = true;

  EditorViewController? _controller;
  final FocusNode _focusNode = FocusNode();

  // Hover properties
  Hover? _hoverData;
  Offset? _hoverPosition;
  Position? _hoverTokenPosition;
  Timer? _hoverDebounceTimer;
  bool _hoverLoading = false;
  CancellationToken? _hoverCancelToken;
  Position? _lastCursorPos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();

    widget.state.eventBus.stream.listen((evt) {
      if (evt.category == 'Command') {
        if (evt.payload == 'find') {
          if (mounted) {
            setState(() => _showFind = true);
          }
        } else if (evt.payload == 'replace') {
          if (mounted) {
            setState(() => _showFind = true);
          }
        } else if (evt.payload == 'gotoLine') {
          _showGotoLineDialog();
        } else if (evt.payload == 'gotoDefinition') {
          _gotoDefinition();
        } else if (evt.payload == 'toggleMinimap') {
          if (mounted) {
            setState(() => _showMinimap = !_showMinimap);
          }
        }
      } else if (evt.category == 'Document') {
        if (evt.payload is DocumentConflictEvent) {
          final conflict = evt.payload as DocumentConflictEvent;
          if (mounted) {
            _showConflictDialog(conflict.path);
          }
        }
      }
    });

    _scrollController.addListener(_handleScrollListener);
    widget.state.addListener(_onStateChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      widget.state.saveAllDirtyDocuments(reason: SaveReason.focusLost);
    }
  }

  void _showConflictDialog(String path) {
    final doc = widget.state.documentService.getDocument(DocumentId(path));
    if (doc == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131024),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              'File Conflict Detected',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        content: Text(
          'The file "$path" has been modified externally.\n\nDo you want to reload it and discard your local unsaved changes, or ignore the external change?',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Compare view is coming soon (Sprint 21).'),
                ),
              );
            },
            child: const Text(
              'Compare (Coming Soon)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              // Ignore: Transition back to dirty state, clear locking
              doc.lockReason = null;
              doc.state = DocumentState.dirty;
              widget.state.triggerRecoverySave();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Ignore',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Reload from disk
              widget.state.reloadFileFromDisk(path);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text(
              'Reload from Disk',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Position? _offsetToPosition(Offset localPosition) {
    if (_controller == null) return null;
    final doc = _controller!.document;
    final double gutterWidth = 52.0;
    final double textPadding = 12.0;
    final double charWidth = 7.2;
    final double lineHeight = 20.0;

    if (localPosition.dx <= gutterWidth) return null;

    final int visualLineIdx = (localPosition.dy / lineHeight).floor();
    if (visualLineIdx < 0 || visualLineIdx >= _controller!.visualLineCount) {
      return null;
    }
    final int actualLine = _controller!.visualToActualLine(visualLineIdx);

    final double textX = localPosition.dx - gutterWidth - textPadding;
    final int col = (textX / charWidth).round() + 1;
    final targetCol = col.clamp(1, doc.lines[actualLine - 1].length + 1);

    return Position(line: actualLine, column: targetCol);
  }

  String? _getWordAt(EditorDocument doc, Position pos) {
    if (pos.line < 1 || pos.line > doc.lines.length) return null;
    final lineStr = doc.lines[pos.line - 1];
    if (lineStr.isEmpty || pos.column > lineStr.length) return null;

    int start = pos.column - 1;
    if (start >= lineStr.length) start = lineStr.length - 1;
    if (start < 0) return null;

    bool isWordChar(String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
    if (!isWordChar(lineStr[start])) return null;

    while (start > 0 && isWordChar(lineStr[start - 1])) {
      start--;
    }
    int end = pos.column - 1;
    while (end < lineStr.length && isWordChar(lineStr[end])) {
      end++;
    }
    return lineStr.substring(start, end);
  }

  List<Diagnostic> _getDiagnosticsAt(String path, Position pos) {
    final docDiags = widget.state.diagnostics.getForFile(path);
    return docDiags.where((d) {
      final s = d.range.start;
      final e = d.range.end;
      if (pos.line < s.line || pos.line > e.line) return false;
      if (pos.line == s.line && pos.column < s.column) return false;
      if (pos.line == e.line && pos.column > e.column) return false;
      return true;
    }).toList();
  }

  void _handleMouseHover(PointerHoverEvent event) {
    final localPosition = event.localPosition;
    final pos = _offsetToPosition(localPosition);

    if (pos == null) {
      _clearHoverState();
      return;
    }

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;
    final doc = activeTab.document;

    final word = _getWordAt(doc, pos);
    final hoverDiags = _getDiagnosticsAt(doc.path, pos);

    if ((word == null || word.isEmpty) && hoverDiags.isEmpty) {
      _clearHoverState();
      return;
    }

    if (_hoverTokenPosition != null &&
        _hoverTokenPosition!.line == pos.line &&
        _hoverTokenPosition!.column == pos.column) {
      return;
    }

    _clearHoverState();
    _hoverTokenPosition = pos;

    _hoverDebounceTimer = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted) return;
      setState(() {
        _hoverLoading = true;
        final double gutterWidth = 52.0;
        final double textPadding = 12.0;
        final double charWidth = 7.2;
        final double lineHeight = 20.0;

        final visualLineIdx = _controller!.actualToVisualLine(pos.line);
        final tokenY = visualLineIdx * lineHeight - _scrollController.offset;

        final lineStr = pos.line <= doc.lines.length
            ? doc.lines[pos.line - 1]
            : '';
        int startCol = pos.column - 1;
        if (lineStr.isNotEmpty) {
          while (startCol > 0 &&
              startCol < lineStr.length &&
              RegExp(r'[a-zA-Z0-9_]').hasMatch(lineStr[startCol - 1])) {
            startCol--;
          }
        }
        final tokenX =
            gutterWidth +
            textPadding +
            (startCol * charWidth) -
            _controller!.viewport.horizontalOffset;

        _hoverPosition = Offset(tokenX, tokenY);
      });

      final mergedContent = StringBuffer();
      if (hoverDiags.isNotEmpty) {
        for (final diag in hoverDiags) {
          String severityEmoji = '❌';
          if (diag.severity == DiagnosticSeverity.warning) severityEmoji = '⚠️';
          if (diag.severity == DiagnosticSeverity.information) {
            severityEmoji = 'ℹ️';
          }
          if (diag.severity == DiagnosticSeverity.hint) severityEmoji = '💡';

          mergedContent.writeln('**$severityEmoji ${diag.message}**');
          mergedContent.writeln('_${diag.source} (${diag.code})_\n');
        }
      }

      if (word != null && word.isNotEmpty) {
        _hoverCancelToken = CancellationToken();
        final ctx = LanguageContext(
          document: doc,
          position: pos,
          workspace: widget.state.activeProject,
          workspaceRevision: 1,
          token: _hoverCancelToken!,
        );

        final res = await widget.state.languageIntel.getHover(ctx);
        if (!mounted) return;

        if (res.success &&
            res.data != null &&
            !_hoverCancelToken!.isCancelled) {
          if (mergedContent.isNotEmpty) {
            mergedContent.writeln('---');
          }
          mergedContent.write(res.data!.contents);
          setState(() {
            _hoverLoading = false;
            _hoverData = Hover(contents: mergedContent.toString());
          });
        } else {
          setState(() {
            _hoverLoading = false;
            if (mergedContent.isNotEmpty) {
              _hoverData = Hover(contents: mergedContent.toString());
            }
          });
        }
      } else {
        setState(() {
          _hoverLoading = false;
          if (mergedContent.isNotEmpty) {
            _hoverData = Hover(contents: mergedContent.toString());
          }
        });
      }
    });
  }

  void _clearHoverState() {
    _hoverDebounceTimer?.cancel();
    _hoverCancelToken?.cancel();
    if (_hoverData != null || _hoverLoading || _hoverPosition != null) {
      setState(() {
        _hoverData = null;
        _hoverLoading = false;
        _hoverPosition = null;
        _hoverTokenPosition = null;
      });
    }
  }

  void _handleMouseExit(PointerExitEvent event) {
    _clearHoverState();
  }

  Widget _buildHoverOverlay() {
    if (_hoverPosition == null || (!_hoverLoading && _hoverData == null)) {
      return const SizedBox.shrink();
    }

    final width = 280.0;
    final double cardPadding = 12.0;

    double topOffset;
    if (_hoverPosition!.dy < 40) {
      topOffset = _hoverPosition!.dy + 25;
    } else {
      topOffset = _hoverPosition!.dy - 45;
    }

    final leftOffset = _hoverPosition!.dx.clamp(
      10.0,
      MediaQuery.of(context).size.width - width - 20,
    );

    return Positioned(
      top: topOffset,
      left: leftOffset,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: const Color(0xE61E1A3A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4C457D), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _hoverLoading
              ? const SizedBox(
                  height: 30,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                )
              : _buildMarkdownContent(_hoverData!.contents),
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(String rawMarkdown) {
    final lines = rawMarkdown.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
        final text = trimmed.replaceAll('**', '');
        children.add(
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      } else if (trimmed.startsWith('**')) {
        children.add(_renderRichLine(line));
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        final content = trimmed.substring(1).trim();
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11),
              ),
              Expanded(child: _renderRichLine(content)),
            ],
          ),
        );
      } else {
        children.add(_renderRichLine(line));
      }
      children.add(const SizedBox(height: 4));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _renderRichLine(String line) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'(\*\*.*?\*\*|`.*?`|\*.*?\*)');
    int lastIdx = 0;

    final matches = regExp.allMatches(line);
    for (final match in matches) {
      if (match.start > lastIdx) {
        spans.add(TextSpan(text: line.substring(lastIdx, match.start)));
      }
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**')) {
        spans.add(
          TextSpan(
            text: matchedText.replaceAll('**', ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else if (matchedText.startsWith('`')) {
        spans.add(
          TextSpan(
            text: matchedText.replaceAll('`', ''),
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFFF472B6),
              backgroundColor: Color(0xFF2C2440),
              fontSize: 10,
            ),
          ),
        );
      } else if (matchedText.startsWith('*')) {
        spans.add(
          TextSpan(
            text: matchedText.replaceAll('*', ''),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      lastIdx = match.end;
    }

    if (lastIdx < line.length) {
      spans.add(TextSpan(text: line.substring(lastIdx)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          height: 1.3,
        ),
        children: spans,
      ),
    );
  }

  void _initController() {
    final activeTab = widget.state.editor.activeTab;
    if (activeTab != null) {
      final doc = activeTab.document;
      final provider = SemanticTokensTokenProvider(
        highlighter: _resolveHighlighter(doc.language),
        languageIntel: widget.state.languageIntel,
        cache: widget.state.languageRegistry.semanticCache,
        document: doc,
        activeProject: widget.state.activeProject,
      );
      _controller = EditorViewController(
        document: doc,
        tokenProvider: provider,
      );
      provider.controller = _controller;
      _controller!.addListener(_rebuildOnControllerChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleScrollListener();
      });
    }
  }

  void _rebuildOnControllerChange() {
    if (!mounted) return;
    setState(() {});

    final cur = _controller?.document.cursor;
    if (cur != null && cur != _lastCursorPos) {
      _lastCursorPos = cur;
      widget.state.codeActionController.triggerCodeActions(isManual: false);
    }
  }

  void _handleScrollListener() {
    if (_controller == null || !_scrollController.hasClients) return;
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    final int firstLine = (scrollOffset / 20.0).floor() + 1;
    final int lastLine = ((scrollOffset + viewportHeight) / 20.0).ceil() + 1;

    _controller!.updateViewport(
      EditorViewport(
        firstVisibleLine: firstLine.clamp(1, _controller!.document.lineCount),
        lastVisibleLine: lastLine.clamp(1, _controller!.document.lineCount),
        horizontalOffset: 0.0,
        verticalOffset: scrollOffset,
        viewportWidth: _scrollController.position.maxScrollExtent,
        viewportHeight: viewportHeight,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeTab = widget.state.editor.activeTab;
    if (activeTab != null &&
        (_controller == null || activeTab.document != _controller!.document)) {
      _controller?.removeListener(_rebuildOnControllerChange);
      _controller?.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _hoverDebounceTimer?.cancel();
    _hoverCancelToken?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScrollListener);
    _scrollController.dispose();
    _controller?.removeListener(_rebuildOnControllerChange);
    _controller?.dispose();
    _focusNode.dispose();
    widget.state.removeListener(_onStateChanged);
    widget.state.completionController.closeSession();
    widget.state.inlineAIController.closeSession();
    _hideCompletionOverlay();
    _hideInlineAIOverlay();
    super.dispose();
  }

  void _handleCloseTab(int index) async {
    final tab = widget.state.editor.tabs[index];
    final doc = tab.document;

    if (doc.state == DocumentState.saving) return;

    if (doc.state == DocumentState.dirty) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF131024),
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          content: Text(
            'Do you want to save changes to ${doc.name} before closing?',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('discard'),
              child: const Text(
                "Don't Save",
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
      if (result == 'cancel' || result == null) return;
      if (result == 'save') {
        await widget.state.dispatcher.execute(
          WorkbenchCommands.fileSave,
          CommandContext(arguments: {}),
        );
      }
    }
    setState(() {
      widget.state.editor.close(index);
    });
    widget.state.triggerRecoverySave();
  }

  void _showGotoLineDialog() {
    if (_controller == null) return;
    final doc = _controller!.document;
    final maxLine = doc.lineCount;

    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131024),
              title: const Text(
                'Go to Line',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter line number (1-$maxLine)...',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final line = int.tryParse(ctrl.text.trim());
                    if (line == null || line < 1 || line > maxLine) {
                      setState(() {
                        errorText = 'Maximum line: $maxLine';
                      });
                    } else {
                      doc.updateCursor(Position(line: line, column: 1));
                      _scrollToLine(line);
                      widget.state.navigationHistory.record(doc.path, line, 1);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Go'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onFindSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _matchLineIndices = [];
        _currentMatchIdx = 0;
      });
      return;
    }

    if (_controller == null) return;
    final doc = _controller!.document;

    final list = <int>[];
    for (var i = 0; i < doc.lineCount; i++) {
      if (doc.lines[i].toLowerCase().contains(query.toLowerCase())) {
        list.add(i + 1);
      }
    }

    setState(() {
      _matchLineIndices = list;
      _currentMatchIdx = 0;
    });

    if (list.isNotEmpty) {
      _scrollToLine(list[0]);
      doc.updateCursor(Position(line: list[0], column: 1));
    }
  }

  void _onFindNext() {
    if (_matchLineIndices.isEmpty || _controller == null) return;
    setState(() {
      _currentMatchIdx = (_currentMatchIdx + 1) % _matchLineIndices.length;
    });
    _scrollToLine(_matchLineIndices[_currentMatchIdx]);
    _controller!.document.updateCursor(
      Position(line: _matchLineIndices[_currentMatchIdx], column: 1),
    );
  }

  void _onFindPrev() {
    if (_matchLineIndices.isEmpty || _controller == null) return;
    setState(() {
      _currentMatchIdx =
          (_currentMatchIdx - 1 + _matchLineIndices.length) %
          _matchLineIndices.length;
    });
    _scrollToLine(_matchLineIndices[_currentMatchIdx]);
    _controller!.document.updateCursor(
      Position(line: _matchLineIndices[_currentMatchIdx], column: 1),
    );
  }

  SyntaxHighlighter _resolveHighlighter(String language) {
    switch (language) {
      case 'dart':
        return DartHighlighter();
      case 'json':
        return JsonHighlighter();
      case 'yaml':
        return YamlHighlighter();
      case 'markdown':
        return MarkdownHighlighter();
      default:
        return TextHighlighter();
    }
  }

  void _scrollToLine(int line) {
    if (_scrollController.hasClients) {
      final targetOffset = (line - 1) * 20.0;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _gotoDefinition() async {
    final name = _symbolController.text.trim();
    if (name.isEmpty) return;

    final token = CancellationToken();
    final res = await widget.state.workbench.symbol.resolveDefinition(
      SymbolId(name),
      token,
    );
    if (res.success && res.data != null) {
      final path = res.data!["path"] ?? '';
      final line = res.data!["line"] ?? 1;
      widget.state.workbench.navigation.jumpToLine(DocumentId(path), line);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Definition not found for symbol: $name')),
      );
    }
  }

  void _findReferences() async {
    final name = _symbolController.text.trim();
    if (name.isEmpty) return;

    final token = CancellationToken();
    final res = await widget.state.workbench.symbol.findReferences(
      SymbolId(name),
      token,
    );
    if (res.success && res.data != null) {
      setState(() {
        _symbolQuery = name;
        _references = res.data!;
      });
    }
  }

  Position _getPrevWordBoundary(EditorDocument doc) {
    final cur = doc.cursor;
    final lineText = doc.lines[cur.line - 1];
    final col = cur.column;
    if (col <= 1) {
      if (cur.line > 1) {
        final prevLineLength = doc.lines[cur.line - 2].length;
        return Position(line: cur.line - 1, column: prevLineLength + 1);
      }
      return cur;
    }

    int i = col - 2;
    while (i >= 0 && lineText[i] == ' ') {
      i--;
    }
    if (i < 0) return Position(line: cur.line, column: 1);

    final isWordChar = RegExp(r'[a-zA-Z0-9_]').hasMatch(lineText[i]);
    while (i >= 0 &&
        RegExp(r'[a-zA-Z0-9_]').hasMatch(lineText[i]) == isWordChar &&
        lineText[i] != ' ') {
      i--;
    }
    return Position(line: cur.line, column: i + 2);
  }

  Position _getNextWordBoundary(EditorDocument doc) {
    final cur = doc.cursor;
    final lineText = doc.lines[cur.line - 1];
    final col = cur.column;
    final len = lineText.length;
    if (col > len) {
      if (cur.line < doc.lineCount) {
        return Position(line: cur.line + 1, column: 1);
      }
      return cur;
    }

    int i = col - 1;
    while (i < len && lineText[i] == ' ') {
      i++;
    }
    if (i >= len) return Position(line: cur.line, column: len + 1);

    final isWordChar = RegExp(r'[a-zA-Z0-9_]').hasMatch(lineText[i]);
    while (i < len &&
        RegExp(r'[a-zA-Z0-9_]').hasMatch(lineText[i]) == isWordChar &&
        lineText[i] != ' ') {
      i++;
    }
    return Position(line: cur.line, column: i + 1);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _controller == null) return;
    final doc = _controller!.document;
    final compController = widget.state.completionController;
    final sigController = widget.state.signatureHelpController;
    final actionController = widget.state.codeActionController;
    final actionSession = actionController.activeSession;

    final isControl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (isControl && event.logicalKey == LogicalKeyboardKey.period) {
      actionController.triggerCodeActions(isManual: true);
      return;
    }

    if (actionSession != null && actionSession.isVisible) {
      final actions = actionSession.actions;
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        actionController.closeSession();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        actionController.executeSelectedAction();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (actions.isNotEmpty) {
          actionSession.selectedIndex =
              (actionSession.selectedIndex - 1 + actions.length) %
              actions.length;
        }
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (actions.isNotEmpty) {
          actionSession.selectedIndex =
              (actionSession.selectedIndex + 1) % actions.length;
        }
        setState(() {});
        return;
      }
    }

    // Detect Ctrl+Shift+Space or Cmd+Shift+Space to trigger signature help manually
    if (isControl && isShift && event.logicalKey == LogicalKeyboardKey.space) {
      sigController.triggerSignatureHelp(SignatureTriggerKind.manual);
      return;
    }

    if (compController.isOverlayVisible) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        compController.closeSession();
        sigController.closeSession();
        actionController.closeSession();
        setState(() {});
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        compController.commitActive();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        compController.selectPrevious();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        compController.selectNext();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        compController.selectPageUp();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        compController.selectPageDown();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        compController.selectHome();
        setState(() {});
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        compController.selectEnd();
        setState(() {});
        return;
      }
    } else if (sigController.isOverlayVisible) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        sigController.closeSession();
        setState(() {});
        return;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.space &&
        HardwareKeyboard.instance.isControlPressed) {
      compController.triggerCompletion(
        const CompletionTrigger(kind: CompletionTriggerKind.manual),
      );
      setState(() {});
      return;
    }

    final context = CommandContext();
    if (widget.state.shortcutManager.handleKeyEvent(event, context)) {
      setState(() {});
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (HardwareKeyboard.instance.isControlPressed) {
        doc.updateCursor(_getPrevWordBoundary(doc));
      } else {
        final cur = doc.cursor;
        if (cur.column > 1) {
          doc.updateCursor(Position(line: cur.line, column: cur.column - 1));
        } else if (cur.line > 1) {
          final prevLineLength = doc.lines[cur.line - 2].length;
          doc.updateCursor(
            Position(line: cur.line - 1, column: prevLineLength + 1),
          );
        }
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (HardwareKeyboard.instance.isControlPressed) {
        doc.updateCursor(_getNextWordBoundary(doc));
      } else {
        final cur = doc.cursor;
        final curLineLength = doc.lines[cur.line - 1].length;
        if (cur.column <= curLineLength) {
          doc.updateCursor(Position(line: cur.line, column: cur.column + 1));
        } else if (cur.line < doc.lineCount) {
          doc.updateCursor(Position(line: cur.line + 1, column: 1));
        }
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final cur = doc.cursor;
      if (cur.line > 1) {
        final prevLineLength = doc.lines[cur.line - 2].length;
        final targetCol = cur.column.clamp(1, prevLineLength + 1);
        doc.updateCursor(Position(line: cur.line - 1, column: targetCol));
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final cur = doc.cursor;
      if (cur.line < doc.lineCount) {
        final nextLineLength = doc.lines[cur.line].length;
        final targetCol = cur.column.clamp(1, nextLineLength + 1);
        doc.updateCursor(Position(line: cur.line + 1, column: targetCol));
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      final cur = doc.cursor;
      final lineText = doc.lines[cur.line - 1];
      int firstNonSpace = lineText.indexOf(RegExp(r'\S')) + 1;
      if (firstNonSpace <= 0) firstNonSpace = 1;
      if (cur.column == firstNonSpace) {
        doc.updateCursor(Position(line: cur.line, column: 1));
      } else {
        doc.updateCursor(Position(line: cur.line, column: firstNonSpace));
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      final cur = doc.cursor;
      final lineText = doc.lines[cur.line - 1];
      doc.updateCursor(Position(line: cur.line, column: lineText.length + 1));
      setState(() {});
    } else {
      final keyChar = event.character;
      if (keyChar != null && keyChar.isNotEmpty) {
        final offset = doc.positionToOffset(doc.cursor);
        final op = InsertTextOperation(index: offset, text: keyChar);
        op.apply(
          doc,
          OperationContext(timestamp: DateTime.now(), source: "keyboard"),
        );
        widget.state.history.recordOperation(doc.id, op);
        setState(() {});

        // Autocomplete typing flow trigger
        final triggerChar = keyChar == '.' ? '.' : null;
        final triggerKind = triggerChar != null
            ? CompletionTriggerKind.triggerCharacter
            : CompletionTriggerKind.automatic;

        if (compController.activeSession != null) {
          compController.filterSession();
        } else {
          if (RegExp(r'[a-zA-Z0-9_.]').hasMatch(keyChar)) {
            compController.triggerCompletion(
              CompletionTrigger(kind: triggerKind, character: triggerChar),
            );
          }
        }

        // Signature help typing flow trigger
        final sigController = widget.state.signatureHelpController;
        if (keyChar == '(' || keyChar == ',') {
          sigController.triggerSignatureHelp(SignatureTriggerKind.automatic);
        } else if (keyChar == ')') {
          sigController.closeSession();
        } else if (sigController.isOverlayVisible) {
          sigController.triggerSignatureHelp(SignatureTriggerKind.automatic);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        final offset = doc.positionToOffset(doc.cursor);
        if (offset > 0) {
          final deleteText = doc.content.substring(offset - 1, offset);
          final op = DeleteTextOperation(index: offset - 1, text: deleteText);
          op.apply(
            doc,
            OperationContext(timestamp: DateTime.now(), source: "keyboard"),
          );
          widget.state.history.recordOperation(doc.id, op);
          setState(() {});

          if (compController.activeSession != null) {
            compController.filterSession();
          }

          final sigController = widget.state.signatureHelpController;
          if (sigController.isOverlayVisible) {
            sigController.triggerSignatureHelp(SignatureTriggerKind.automatic);
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final offset = doc.positionToOffset(doc.cursor);
        final op = InsertTextOperation(index: offset, text: "\n");
        op.apply(
          doc,
          OperationContext(timestamp: DateTime.now(), source: "keyboard"),
        );
        widget.state.history.recordOperation(doc.id, op);
        setState(() {});

        compController.closeSession();
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_controller == null) return;
    widget.state.completionController.closeSession();
    _focusNode.requestFocus();
    final doc = _controller!.document;
    final localPosition = details.localPosition;

    final double gutterWidth = 52.0;
    if (localPosition.dx <= gutterWidth) {
      final int visualLineIdx = (localPosition.dy / 20.0).floor();
      if (visualLineIdx >= 0 && visualLineIdx < _controller!.visualLineCount) {
        final int actualLine = _controller!.visualToActualLine(visualLineIdx);
        doc.toggleFold(actualLine);
        setState(() {});
      }
      return;
    }

    final int visualLineIdx = (localPosition.dy / 20.0).floor();
    if (visualLineIdx >= 0 && visualLineIdx < _controller!.visualLineCount) {
      final int targetLine = _controller!.visualToActualLine(visualLineIdx);

      final double charWidth = 7.2;
      final double textX =
          localPosition.dx -
          gutterWidth -
          12.0 +
          _controller!.viewport.horizontalOffset;
      final int col = (textX / charWidth).round() + 1;
      final targetCol = col.clamp(1, doc.lines[targetLine - 1].length + 1);

      doc.updateCursor(Position(line: targetLine, column: targetCol));
      doc.updateSelection(null);
      setState(() {});
    }
  }

  List<Position> _findMatchingBrackets(EditorDocument doc) {
    final cursorOffset = doc.positionToOffset(doc.cursor);
    final content = doc.content;
    if (content.isEmpty) return [];

    int bracketOffset = -1;
    String char = '';

    if (cursorOffset > 0) {
      final prevChar = content[cursorOffset - 1];
      if ('{}[Dependency]()'.contains(prevChar)) {
        bracketOffset = cursorOffset - 1;
        char = prevChar;
      }
    }
    if (bracketOffset == -1 && cursorOffset < content.length) {
      final nextChar = content[cursorOffset];
      if ('{}[Dependency]()'.contains(nextChar)) {
        bracketOffset = cursorOffset;
        char = nextChar;
      }
    }

    if (bracketOffset == -1) return [];

    final Map<String, String> pairs = {
      '{': '}',
      '}': '{',
      '[': ']',
      ']': '[',
      '(': ')',
      ')': '(',
    };
    final targetChar = pairs[char]!;
    final isForward = '{[('.contains(char);

    final int searchStart = isForward
        ? bracketOffset + 1
        : (bracketOffset - 1000).clamp(0, content.length);
    final int searchEnd = isForward
        ? (bracketOffset + 1000).clamp(0, content.length)
        : bracketOffset;

    int depth = 1;
    if (isForward) {
      for (int i = searchStart; i < searchEnd; i++) {
        if (content[i] == char) {
          depth++;
        } else if (content[i] == targetChar) {
          depth--;
          if (depth == 0) {
            return [
              doc.offsetToPosition(bracketOffset),
              doc.offsetToPosition(i),
            ];
          }
        }
      }
    } else {
      for (int i = searchEnd - 1; i >= searchStart; i--) {
        if (content[i] == char) {
          depth++;
        } else if (content[i] == targetChar) {
          depth--;
          if (depth == 0) {
            return [
              doc.offsetToPosition(bracketOffset),
              doc.offsetToPosition(i),
            ];
          }
        }
      }
    }

    return [];
  }

  Map<String, String?> _getStickyHeaderSymbol() {
    if (_controller == null) return {'class': null, 'method': null};
    final doc = _controller!.document;
    final outline =
        widget.state.documentService.getOutline(DocumentId(doc.path)) ?? [];
    final firstLine = _controller!.viewport.firstVisibleLine;

    String? className;
    String? methodName;
    int classLineMax = -1;
    int methodLineMax = -1;

    for (final sym in outline) {
      final symLine = sym['line'] as int? ?? 1;
      if (sym['kind'] == 'Class') {
        if (symLine <= firstLine && symLine > classLineMax) {
          className = sym['name'];
          classLineMax = symLine;

          final children = sym['children'] as List? ?? [];
          for (final child in children) {
            final childLine = child['line'] as int? ?? 1;
            if (childLine <= firstLine && childLine > methodLineMax) {
              methodName = child['name'];
              methodLineMax = childLine;
            }
          }
        }
      }
    }
    return {'class': className, 'method': methodName};
  }

  Widget _buildStickyHeader() {
    final symbols = _getStickyHeaderSymbol();
    final className = symbols['class'];
    final methodName = symbols['method'];

    if (className == null && methodName == null) return const SizedBox();

    return Positioned(
      top: 0,
      left: 52.0,
      right: _showMinimap ? 80.0 : 0.0,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131024).withValues(alpha: 0.95),
          border: const Border(bottom: BorderSide(color: Color(0xFF2C284D))),
        ),
        child: Row(
          children: [
            if (className != null) ...[
              const Icon(Icons.category, size: 12, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              Text(
                className,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (methodName != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 12, color: Colors.white30),
              const SizedBox(width: 8),
              const Icon(Icons.functions, size: 12, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(
                methodName,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.state.editor.activeTab;

    if (activeTab == null || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code, size: 48, color: Colors.white10),
            SizedBox(height: 12),
            Text(
              'No files open.\nSelect a file from the Project Explorer or press Cmd+Shift+P.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final doc = activeTab.document;
    final int visualLineCount = _controller!.visualLineCount;
    final double editorHeight = math.max(300.0, visualLineCount * 20.0 + 40.0);

    final bracketMatches = _findMatchingBrackets(doc);
    final paintCtx = PaintContext(
      snapshot: doc.createSnapshot(),
      viewport: _controller!.viewport,
      theme: EditorTheme.defaultDark,
      gutters: [
        LineNumberGutterProvider(),
        DiagnosticsGutterProvider(widget.state),
      ],
      decorations: [
        DiagnosticsDecorationProvider(widget.state),
        InlineAIDecorationProvider(widget.state),
      ],
      controller: _controller!,
      bracketMatches: bracketMatches,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      body: Column(
        children: [
          // Tabs bar
          Container(
            height: 38,
            color: const Color(0xFF131024),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.state.editor.tabs.length,
              itemBuilder: (context, index) {
                final tab = widget.state.editor.tabs[index];
                final isCurrent = index == widget.state.editor.activeTabIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      widget.state.editor.activate(index);
                    });
                    widget.state.navigation.openFile(tab.document.path);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF0F0C1B)
                          : const Color(0xFF131024),
                      border: Border(
                        right: const BorderSide(color: Color(0xFF2C284D)),
                        top: BorderSide(
                          color: isCurrent
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (tab.document.state == DocumentState.dirty ||
                            tab.document.state == DocumentState.saving)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tab.document.state == DocumentState.saving
                                  ? const Color(0xFFFBBF24)
                                  : Colors.white,
                            ),
                          ),
                        Text(
                          tab.document.state == DocumentState.dirty
                              ? '${tab.document.name} •'
                              : tab.document.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (tab.document.state == DocumentState.saving)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFFFBBF24),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _handleCloseTab(index),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white30,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Breadcrumbs symbols bar
          BreadcrumbSymbolsWidget(state: widget.state),
          // Actions Toolbar
          Container(
            height: 36,
            color: const Color(0xFF16132A),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  size: 16,
                  color: Color(0xFFA78BFA),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Inspect Symbol: ',
                  style: TextStyle(fontSize: 11, color: Colors.white30),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _symbolController,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type class or method name...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _gotoDefinition,
                  icon: const Icon(Icons.gps_fixed, size: 12),
                  label: const Text(
                    'Go to Definition (F12)',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                TextButton.icon(
                  onPressed: _findReferences,
                  icon: const Icon(Icons.travel_explore, size: 12),
                  label: const Text(
                    'Find References',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C284D)),
          // Custom Drawn Editor
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: KeyboardListener(
                        focusNode: _focusNode,
                        onKeyEvent: _handleKeyEvent,
                        child: MouseRegion(
                          onHover: _handleMouseHover,
                          onExit: _handleMouseExit,
                          child: GestureDetector(
                            onTapDown: _handleTapDown,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: SizedBox(
                                height: editorHeight,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: EditorRenderer(context, paintCtx),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showMinimap)
                      MinimapWidget(
                        viewController: _controller!,
                        scrollController: _scrollController,
                        state: widget.state,
                      ),
                  ],
                ),
                if (_scrollController.hasClients &&
                    _scrollController.offset > 10)
                  _buildStickyHeader(),
                _buildHoverOverlay(),
                if (_showFind)
                  FindOverlayWidget(
                    onSearchChanged: _onFindSearchChanged,
                    onNext: _onFindNext,
                    onPrev: _onFindPrev,
                    onClose: () {
                      setState(() {
                        _showFind = false;
                        _matchLineIndices = [];
                      });
                    },
                    totalMatches: _matchLineIndices.length,
                    currentIdx: _currentMatchIdx,
                  ),
              ],
            ),
          ),
          if (_references.isNotEmpty)
            ReferencesPanel(
              state: widget.state,
              references: _references,
              symbolName: _symbolQuery,
              onClose: () {
                setState(() {
                  _references = [];
                  _symbolQuery = '';
                });
              },
            ),
          if (widget.state.showProblemsPanel)
            ProblemsPanel(
              state: widget.state,
              onClose: () {
                widget.state.toggleProblemsPanel();
              },
            ),
        ],
      ),
    );
  }

  void _onStateChanged() {
    if (!mounted) return;
    final compController = widget.state.completionController;
    if (compController.isOverlayVisible &&
        compController.activeSession != null) {
      _showCompletionOverlay(compController.activeSession!);
    } else {
      _hideCompletionOverlay();
    }

    final sigController = widget.state.signatureHelpController;
    if (sigController.isOverlayVisible && sigController.activeSession != null) {
      _showSignatureOverlay(sigController.activeSession!);
    } else {
      _hideSignatureOverlay();
    }

    final actionController = widget.state.codeActionController;
    final actionSession = actionController.activeSession;
    if (actionSession != null) {
      if (actionSession.isVisible) {
        _hideCodeActionLightbulb();
        _showCodeActionsOverlay(actionSession);
      } else {
        _hideCodeActionsOverlay();
        _showCodeActionLightbulb(actionSession);
      }
    } else {
      _hideCodeActionLightbulb();
      _hideCodeActionsOverlay();
    }

    final inlineController = widget.state.inlineAIController;
    if (inlineController.activeSession != null) {
      _showInlineAIOverlay(inlineController.activeSession!);
    } else {
      _hideInlineAIOverlay();
    }
  }

  void _showCompletionOverlay(CompletionSession session) {
    _hideCompletionOverlay();

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;
    final doc = activeTab.document;
    final cursor = doc.cursor;

    final double gutterWidth = 52.0;
    final double textPadding = 12.0;
    final double charWidth = 7.2;
    final double lineHeight = 20.0;

    final visualLineIdx =
        _controller?.actualToVisualLine(cursor.line) ?? (cursor.line - 1);
    final caretY = visualLineIdx * lineHeight - _scrollController.offset;
    final caretX =
        gutterWidth +
        textPadding +
        (cursor.column * charWidth) -
        (_controller?.viewport.horizontalOffset ?? 0.0);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    final globalCursorX = globalOffset.dx + caretX;
    final globalCursorY = globalOffset.dy + caretY + lineHeight;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return CompletionOverlayWidget(
          session: session,
          controller: widget.state.completionController,
          globalX: globalCursorX,
          globalY: globalCursorY,
        );
      },
    );

    overlay.insert(entry);
    widget.state.completionController.updateOverlay(entry);
  }

  void _hideCompletionOverlay() {
    widget.state.completionController.hideOverlay();
  }

  void _showInlineAIOverlay(InlineAISession session) {
    _hideInlineAIOverlay();

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;
    final doc = activeTab.document;
    final cursor = doc.cursor;

    final double gutterWidth = 52.0;
    final double textPadding = 12.0;
    final double charWidth = 7.2;
    final double lineHeight = 20.0;

    final visualLineIdx =
        _controller?.actualToVisualLine(cursor.line) ?? (cursor.line - 1);
    final caretY = visualLineIdx * lineHeight - _scrollController.offset;
    final caretX =
        gutterWidth +
        textPadding +
        (cursor.column * charWidth) -
        (_controller?.viewport.horizontalOffset ?? 0.0);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    final globalCursorX = globalOffset.dx + caretX;
    final globalCursorY = globalOffset.dy + caretY + lineHeight;

    final entry = OverlayEntry(
      builder: (context) {
        return InlineAIOverlayWidget(
          session: session,
          controller: widget.state.inlineAIController,
          globalX: globalCursorX,
          globalY: globalCursorY,
        );
      },
    );

    widget.state.overlayManager.register(
      OverlayDescriptor(
        id: 'inline-ai',
        type: OverlayType.inlineAI,
        entry: entry,
      ),
    );
    widget.state.overlayManager.show(context, 'inline-ai');
  }

  void _hideInlineAIOverlay() {
    widget.state.overlayManager.hide('inline-ai');
  }

  void _showSignatureOverlay(SignatureSession session) {
    _hideSignatureOverlay();

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;

    final double gutterWidth = 52.0;
    final double textPadding = 12.0;
    final double charWidth = 7.2;
    final double lineHeight = 20.0;

    final anchor = session.anchorPosition;
    final visualLineIdx =
        _controller?.actualToVisualLine(anchor.line) ?? (anchor.line - 1);
    final caretY = visualLineIdx * lineHeight - _scrollController.offset;
    final caretX =
        gutterWidth +
        textPadding +
        (anchor.column * charWidth) -
        (_controller?.viewport.horizontalOffset ?? 0.0);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    final globalCursorX = globalOffset.dx + caretX;
    final globalCursorY = globalOffset.dy + caretY + lineHeight + 4;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return SignatureHelpOverlayWidget(
          session: session,
          controller: widget.state.signatureHelpController,
          globalX: globalCursorX,
          globalY: globalCursorY,
        );
      },
    );

    overlay.insert(entry);
    widget.state.signatureHelpController.updateOverlay(entry);
  }

  void _hideSignatureOverlay() {
    widget.state.signatureHelpController.hideOverlay();
  }

  void _showCodeActionLightbulb(CodeActionSession session) {
    _hideCodeActionLightbulb();

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;

    final double gutterWidth = 52.0;
    final double lineHeight = 20.0;

    final pos = session.position;
    final visualLineIdx =
        _controller?.actualToVisualLine(pos.line) ?? (pos.line - 1);
    final caretY = visualLineIdx * lineHeight - _scrollController.offset;

    final caretX = gutterWidth - 28.0;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    final globalCursorX = globalOffset.dx + caretX;
    final globalCursorY = globalOffset.dy + caretY + 1.0;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return CodeActionLightbulb(
          session: session,
          controller: widget.state.codeActionController,
          globalX: globalCursorX,
          globalY: globalCursorY,
        );
      },
    );

    overlay.insert(entry);
    widget.state.codeActionController.updateLightbulbOverlay(entry);
  }

  void _hideCodeActionLightbulb() {
    widget.state.codeActionController.updateLightbulbOverlay(null);
  }

  void _showCodeActionsOverlay(CodeActionSession session) {
    _hideCodeActionsOverlay();

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;

    final double gutterWidth = 52.0;
    final double textPadding = 12.0;
    final double charWidth = 7.2;
    final double lineHeight = 20.0;

    final pos = session.position;
    final visualLineIdx =
        _controller?.actualToVisualLine(pos.line) ?? (pos.line - 1);
    final caretY = visualLineIdx * lineHeight - _scrollController.offset;
    final caretX =
        gutterWidth +
        textPadding +
        (pos.column * charWidth) -
        (_controller?.viewport.horizontalOffset ?? 0.0);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    final globalCursorX = globalOffset.dx + caretX;
    final globalCursorY = globalOffset.dy + caretY + lineHeight + 2.0;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return CodeActionOverlayWidget(
          session: session,
          controller: widget.state.codeActionController,
          globalX: globalCursorX,
          globalY: globalCursorY,
        );
      },
    );

    overlay.insert(entry);
    widget.state.codeActionController.updateActionsOverlay(entry);
  }

  void _hideCodeActionsOverlay() {
    widget.state.codeActionController.updateActionsOverlay(null);
  }
}
