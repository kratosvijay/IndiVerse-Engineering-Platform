import 'package:flutter/material.dart';

import '../../../core/state/studio_state.dart';
import '../../../core/services/workbench_providers.dart';
import '../../../models/ids.dart';
import '../highlighting/abstract_highlighter.dart';
import '../highlighting/dart_highlighter.dart';
import '../highlighting/json_highlighter.dart';
import '../highlighting/yaml_highlighter.dart';
import '../highlighting/markdown_highlighter.dart';
import '../highlighting/text_highlighter.dart';
import 'breadcrumb_symbols_widget.dart';
import 'references_panel.dart';
import 'find_overlay_widget.dart';

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

  @override
  void initState() {
    super.initState();
    widget.state.eventBus.stream.listen((evt) {
      if (evt.category == 'Command') {
        if (evt.payload == 'find') {
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
  }

  void _showGotoLineDialog() {
    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;
    final doc = activeTab.document;
    final lines = doc.content.split('\n');
    final maxLine = lines.length;

    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131024),
              title: const Text('Go to Line', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                      widget.state.workbench.navigation.jumpToLine(DocumentId(doc.path), line);
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

    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) return;
    final lines = activeTab.document.content.split('\n');

    final list = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
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
    }
  }

  void _onFindNext() {
    if (_matchLineIndices.isEmpty) return;
    setState(() {
      _currentMatchIdx = (_currentMatchIdx + 1) % _matchLineIndices.length;
    });
    _scrollToLine(_matchLineIndices[_currentMatchIdx]);
  }

  void _onFindPrev() {
    if (_matchLineIndices.isEmpty) return;
    setState(() {
      _currentMatchIdx = (_currentMatchIdx - 1 + _matchLineIndices.length) % _matchLineIndices.length;
    });
    _scrollToLine(_matchLineIndices[_currentMatchIdx]);
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

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final doc = widget.state.editor.activeTab?.document;
    if (doc != null && doc.cursorLine > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLine(doc.cursorLine);
      });
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
    final res = await widget.state.workbench.symbol.resolveDefinition(SymbolId(name), token);
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
    final res = await widget.state.workbench.symbol.findReferences(SymbolId(name), token);
    if (res.success && res.data != null) {
      setState(() {
        _symbolQuery = name;
        _references = res.data!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.state.editor.activeTab;

    if (activeTab == null) {
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
    final lines = doc.content.split('\n');
    final highlighter = _resolveHighlighter(doc.language);

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
                      color: isCurrent ? const Color(0xFF0F0C1B) : const Color(0xFF131024),
                      border: Border(
                        right: const BorderSide(color: Color(0xFF2C284D)),
                        top: BorderSide(
                          color: isCurrent ? const Color(0xFF8B5CF6) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tab.document.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              widget.state.editor.close(index);
                            });
                          },
                          child: const Icon(Icons.close, size: 12, color: Colors.white30),
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
                const Icon(Icons.psychology, size: 16, color: Color(0xFFA78BFA)),
                const SizedBox(width: 8),
                const Text('Inspect Symbol: ', style: TextStyle(fontSize: 11, color: Colors.white30)),
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
                  label: const Text('Go to Definition (F12)', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: _findReferences,
                  icon: const Icon(Icons.travel_explore, size: 12),
                  label: const Text('Find References', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C284D)),
          // Line-numbered read-only viewer + Minimap
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: lines.length,
                        itemExtent: 20.0,
                        itemBuilder: (context, index) {
                          final lineNum = index + 1;
                          final lineText = lines[index];
                          final isHighlight = lineNum == doc.cursorLine;

                          // Search highlight checker
                          final isSearchMatch = _findQuery.isNotEmpty && lineText.toLowerCase().contains(_findQuery.toLowerCase());

                          return Container(
                            color: isHighlight
                                ? const Color(0xFF2C1C4D)
                                : isSearchMatch
                                    ? const Color(0xFF3B2A1A)
                                    : Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    '$lineNum',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isHighlight ? const Color(0xFFA78BFA) : Colors.white24,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(width: 1, color: Color(0xFF2C284D)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: RichText(
                                      text: highlighter.highlight(context, lineText),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Minimap Sidebar Strip
                    Container(
                      width: 32,
                      color: const Color(0xFF0F0C1B),
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lines.length > 120 ? 120 : lines.length,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 0.5),
                            color: Colors.white10,
                          );
                        },
                      ),
                    ),
                  ],
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
