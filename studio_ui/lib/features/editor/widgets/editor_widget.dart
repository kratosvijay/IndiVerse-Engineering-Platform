import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/studio_state.dart';
import '../../../core/services/workbench_providers.dart';
import '../../../core/services/workbench_commands.dart';
import '../../../models/ids.dart';
import '../../../models/editor_document.dart';
import '../../../models/edit_operation.dart';
import '../../../core/services/keyboard_shortcut_manager.dart';
import '../highlighting/abstract_highlighter.dart';
import '../highlighting/dart_highlighter.dart';
import '../highlighting/json_highlighter.dart';
import '../highlighting/yaml_highlighter.dart';
import '../highlighting/markdown_highlighter.dart';
import '../highlighting/text_highlighter.dart';
import 'breadcrumb_symbols_widget.dart';
import 'references_panel.dart';
import 'find_overlay_widget.dart';
import '../controllers/editor_view_controller.dart';
import 'editor_renderer.dart';

class EditorWidget extends StatefulWidget {
  final StudioState state;

  const EditorWidget({super.key, required this.state});

  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _symbolController = TextEditingController();
  List<Map<String, dynamic>> _references = [];
  String _symbolQuery = '';

  // Find properties
  bool _showFind = false;
  List<int> _matchLineIndices = [];
  int _currentMatchIdx = 0;
  String _findQuery = '';

  EditorViewController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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
        }
      }
    });

    _scrollController.addListener(_handleScrollListener);
  }

  void _initController() {
    final activeTab = widget.state.editor.activeTab;
    if (activeTab != null) {
      final doc = activeTab.document;
      final provider = HighlighterTokenProvider(
        _resolveHighlighter(doc.language),
      );
      _controller = EditorViewController(
        document: doc,
        tokenProvider: provider,
      );
      _controller!.addListener(_rebuildOnControllerChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleScrollListener();
      });
    }
  }

  void _rebuildOnControllerChange() {
    if (mounted) setState(() {});
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
    _scrollController.removeListener(_handleScrollListener);
    _scrollController.dispose();
    _controller?.removeListener(_rebuildOnControllerChange);
    _controller?.dispose();
    _focusNode.dispose();
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
        _findQuery = '';
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
      _findQuery = query;
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _controller == null) return;
    final doc = _controller!.document;

    final context = CommandContext();
    if (widget.state.shortcutManager.handleKeyEvent(event, context)) {
      setState(() {});
      return;
    }

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
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final cur = doc.cursor;
      if (cur.column > 1) {
        doc.updateCursor(Position(line: cur.line, column: cur.column - 1));
      } else if (cur.line > 1) {
        final prevLineLength = doc.lines[cur.line - 2].length;
        doc.updateCursor(
          Position(line: cur.line - 1, column: prevLineLength + 1),
        );
      }
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final cur = doc.cursor;
      final curLineLength = doc.lines[cur.line - 1].length;
      if (cur.column <= curLineLength) {
        doc.updateCursor(Position(line: cur.line, column: cur.column + 1));
      } else if (cur.line < doc.lineCount) {
        doc.updateCursor(Position(line: cur.line + 1, column: 1));
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
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_controller == null) return;
    _focusNode.requestFocus();
    final doc = _controller!.document;
    final localPosition = details.localPosition;

    final int line = (localPosition.dy / 20.0).floor() + 1;
    final targetLine = line.clamp(1, doc.lineCount);

    final double charWidth = 7.2;
    final double textX =
        localPosition.dx - 48.0 - 12.0 + _controller!.viewport.horizontalOffset;
    final int col = (textX / charWidth).round() + 1;
    final targetCol = col.clamp(1, doc.lines[targetLine - 1].length + 1);

    doc.updateCursor(Position(line: targetLine, column: targetCol));
    doc.updateSelection(null);
    setState(() {});
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
    final double editorHeight = math.max(300.0, doc.lineCount * 20.0 + 40.0);

    final paintCtx = PaintContext(
      snapshot: doc.createSnapshot(),
      viewport: _controller!.viewport,
      theme: EditorTheme.defaultDark,
      gutters: [LineNumberGutterProvider()],
      decorations: [],
      controller: _controller!,
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
                KeyboardListener(
                  focusNode: _focusNode,
                  onKeyEvent: _handleKeyEvent,
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
                if (_showFind)
                  FindOverlayWidget(
                    onSearchChanged: _onFindSearchChanged,
                    onNext: _onFindNext,
                    onPrev: _onFindPrev,
                    onClose: () {
                      setState(() {
                        _showFind = false;
                        _findQuery = '';
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
        ],
      ),
    );
  }
}
