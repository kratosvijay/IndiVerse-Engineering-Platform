import 'package:flutter/material.dart';

import 'core/state/studio_state.dart';
import 'features/editor/widgets/editor_widget.dart';
import 'features/search/search_widget.dart';
import 'features/command_palette/command_palette_widget.dart';
import 'features/inspector/inspector_widget.dart';
import 'features/architecture/architecture_widget.dart';
import 'features/agents/agents_widget.dart';
import 'features/metrics/metrics_widget.dart';
import 'features/explorer/widgets/collapsible_accordion_sidebar.dart';
import 'features/editor/widgets/welcome_widget.dart';
import 'features/quick_open/widgets/quick_open_widget.dart';
import 'features/diagnostics/diagnostics_widget.dart';
import 'models/tree_node.dart';
import 'core/services/keyboard_shortcut_manager.dart';

void main() {
  runApp(const StudioApp());
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndiVerse Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF6366F1),
          surface: Color(0xFF1E1B4B),
        ),
      ),
      home: const StudioDashboard(),
    );
  }
}

class StudioDashboard extends StatefulWidget {
  const StudioDashboard({super.key});

  @override
  State<StudioDashboard> createState() => _StudioDashboardState();
}

class _StudioDashboardState extends State<StudioDashboard> {
  final StudioState _studioState = StudioState();
  bool _showCommandPalette = false;
  bool _showQuickOpen = false;

  @override
  void initState() {
    super.initState();
    _studioState.connect(18080);
    _initializeWorkspaceSession();

    _studioState.eventBus.stream.listen((evt) {
      if (evt.category == 'Command') {
        if (evt.payload == 'quickOpen') {
          setState(() => _showQuickOpen = !_showQuickOpen);
        } else if (evt.payload == 'showCommands') {
          setState(() => _showCommandPalette = !_showCommandPalette);
        }
      }
    });
  }

  void _initializeWorkspaceSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_studioState.editor.tabs.isEmpty) {
      String? defaultPath;
      final rootNodes = _studioState.rootNodes;

      final hasReadme = rootNodes.any((n) => n.name.toLowerCase() == 'readme.md');
      if (hasReadme) {
        defaultPath = 'README.md';
      } else {
        final hasLibMain = rootNodes.any((n) => n.name == 'lib');
        if (hasLibMain) {
          defaultPath = 'lib/main.dart';
        } else {
          final firstFile = rootNodes.firstWhere(
            (n) => !n.isDirectory,
            orElse: () => TreeNode(name: '', path: '', isDirectory: false),
          );
          if (firstFile.path.isNotEmpty) {
            defaultPath = firstFile.path;
          }
        }
      }

      if (defaultPath != null) {
        _studioState.openFile(defaultPath);
      }
    }
  }

  @override
  void dispose() {
    _studioState.disconnect();
    super.dispose();
  }

  Widget _buildActivePanel(String tab) {
    if (_studioState.editor.tabs.isEmpty) {
      return WelcomeWidget(state: _studioState);
    }

    switch (tab) {
      case 'Workspace':
        return EditorWidget(state: _studioState);
      case 'Search':
        return SearchWidget(state: _studioState);
      case 'Agents':
        return AgentsWidget(state: _studioState);
      case 'Architecture':
        return ArchitectureWidget(state: _studioState);
      case 'Metrics':
        return MetricsWidget(state: _studioState);
      case 'Diagnostics':
        return DiagnosticsWidget(state: _studioState);
      default:
        return EditorWidget(state: _studioState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _studioState,
      builder: (context, _) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            final ctx = CommandContext();
            _studioState.shortcutManager.handleKeyEvent(event, ctx);
          },
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Row(
                        children: [
                          CollapsibleAccordionSidebar(state: _studioState),
                          Expanded(
                            child: _buildActivePanel(_studioState.activeTab),
                          ),
                          InspectorWidget(state: _studioState),
                        ],
                      ),
                    ),
                    _buildStatusBar(),
                  ],
                ),
                if (_showCommandPalette)
                  CommandPaletteWidget(
                    state: _studioState,
                    onClose: () {
                      setState(() {
                        _showCommandPalette = false;
                      });
                    },
                  ),
                if (_showQuickOpen)
                  QuickOpenWidget(
                    state: _studioState,
                    onClose: () {
                      setState(() {
                        _showQuickOpen = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF16132A),
        border: Border(bottom: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'IndiVerse Studio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1065),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _studioState.version,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA78BFA),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children:
                [
                  'Workspace',
                  'Search',
                  'Agents',
                  'Architecture',
                  'Metrics',
                  'Diagnostics',
                ].map((tab) {
                  final active = _studioState.activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextButton(
                      onPressed: () => _studioState.setTab(tab),
                      style: TextButton.styleFrom(
                        foregroundColor: active ? Colors.white : Colors.white54,
                        backgroundColor: active
                            ? const Color(0xFF2E1065)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(tab, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _studioState.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _studioState.isConnected
                    ? 'Connected (:18080)'
                    : 'Disconnected',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final activeTab = _studioState.editor.activeTab;
    final doc = activeTab?.document;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16132A),
        border: Border(top: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Status: ${_studioState.agentWorkflowStatus}',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
          if (doc != null) ...[
            Row(
              children: [
                Text(
                  'Ln ${doc.cursorLine}, Col 1',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Spaces: 2',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(width: 16),
                const Text(
                  'UTF-8',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(width: 16),
                const Text(
                  'LF',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                const SizedBox(width: 16),
                Text(
                  doc.language.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
          Row(
            children: [
              const Text(
                'Tokens: 14.2K',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Online',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
