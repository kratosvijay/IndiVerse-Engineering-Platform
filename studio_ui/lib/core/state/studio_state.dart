import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/selection.dart';
import '../../models/command.dart';
import '../../models/editor_document.dart';
import '../../models/tree_node.dart';
import '../services/navigation_service.dart';
import '../services/workspace_cache.dart';
import '../../features/editor/controllers/editor_controller.dart';
import '../../features/explorer/controllers/explorer_controller.dart';

class StudioState extends ChangeNotifier {
  String _activeTab = 'Workspace';
  int _serverPort = 18080;
  bool _isConnected = false;
  
  Map<String, String> _health = {};
  Map<String, dynamic> _metrics = {};
  Map<String, bool> _features = {};
  final List<String> _eventLogs = [];
  
  String _agentWorkflowStatus = 'Idle';
  String _version = "v1.1.0";
  String _activeProject = "indiverse-engineering-platform";
  String _branchName = "main";
  
  Selection? _currentSelection;
  final List<TreeNode> _rootNodes = [];
  
  final WorkspaceCache workspaceCache = WorkspaceCache();
  late final NavigationService navigation;
  final EditorController editor = EditorController();
  final ExplorerController explorer = ExplorerController();
  
  final List<Command> commandRegistry = [];
  WebSocketChannel? _wsChannel;

  List<dynamic> _searchResults = [];
  
  // Getters
  String get activeTab => _activeTab;
  int get serverPort => _serverPort;
  bool get isConnected => _isConnected;
  Map<String, String> get health => _health;
  Map<String, dynamic> get metrics => _metrics;
  Map<String, bool> get features => _features;
  List<String> get eventLogs => _eventLogs;
  String get agentWorkflowStatus => _agentWorkflowStatus;
  String get version => _version;
  String get activeProject => _activeProject;
  String get branchName => _branchName;
  Selection? get currentSelection => _currentSelection;
  List<TreeNode> get rootNodes => _rootNodes;
  List<dynamic> get searchResults => _searchResults;

  set agentWorkflowStatus(String val) {
    _agentWorkflowStatus = val;
    notifyListeners();
  }

  Future<void> executeSearch(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/search?q=$query'),
      );
      final data = jsonDecode(res.body);
      _searchResults = data['results'] ?? [];
      notifyListeners();
    } catch (_) {}
  }

  StudioState() {
    navigation = NavigationService(this);
    _registerDefaultCommands();
  }

  void _registerDefaultCommands() {
    registerCommand(Command(
      id: "workspace.reload",
      title: "Reload Workspace",
      description: "Force re-index and reload files structure",
      category: "Workspace",
      execute: (ctx) async {
        await reloadWorkspace();
      },
    ));
    registerCommand(Command(
      id: "agent.run",
      title: "Run Agent",
      description: "Trigger Multi-Agent Planning Workflow",
      category: "Agent",
      execute: (ctx) async {
        triggerAgentWorkflow();
      },
    ));
  }

  void registerCommand(Command cmd) {
    commandRegistry.add(cmd);
  }

  Future<void> executeCommand(String id, CommandContext context) async {
    final cmd = commandRegistry.firstWhere((c) => c.id == id);
    await cmd.execute(context);
    notifyListeners();
  }

  void setTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void connect(int port) {
    _serverPort = port;
    _isConnected = true;
    _fetchInitialData();
    _subscribeToEvents(port);
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    _wsChannel?.sink.close();
    notifyListeners();
  }

  Future<void> _fetchInitialData() async {
    try {
      final hRes = await http.get(Uri.parse('http://localhost:$_serverPort/api/health'));
      final fRes = await http.get(Uri.parse('http://localhost:$_serverPort/api/features'));
      final mRes = await http.get(Uri.parse('http://localhost:$_serverPort/api/metrics'));
      final vRes = await http.get(Uri.parse('http://localhost:$_serverPort/api/v1/version'));

      _health = Map<String, String>.from(jsonDecode(hRes.body));
      _features = Map<String, bool>.from(jsonDecode(fRes.body));
      _metrics = Map<String, dynamic>.from(jsonDecode(mRes.body));
      final vJson = jsonDecode(vRes.body);
      _version = vJson['data']['platform'] ?? 'v1.1.0';
      final wRes = await http.get(Uri.parse('http://localhost:$_serverPort/api/v1/workspace'));
      final wJson = jsonDecode(wRes.body);
      _activeProject = wJson['data']['activeProject'] ?? 'indiverse-engineering-platform';
      _branchName = wJson['data']['branch'] ?? 'main';

      await reloadWorkspace();
    } catch (_) {}
  }

  Future<void> reloadWorkspace() async {
    workspaceCache.clear();
    _rootNodes.clear();
    final treeData = await fetchDirectoryContents('/');
    _rootNodes.addAll(treeData);
    notifyListeners();
  }

  Future<List<TreeNode>> fetchDirectoryContents(String path) async {
    final cached = workspaceCache.get(path);
    if (cached != null) return cached;

    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace?path=$path&recursive=false'),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final filesList = envelope["data"]["files"] as List? ?? [];
        final nodes = filesList.map((item) {
          return TreeNode(
            name: item["name"] ?? '',
            path: item["path"] ?? '',
            isDirectory: item["type"] == "directory",
            size: item["size"] ?? 0,
            modified: item["modified"] ?? '',
          );
        }).toList();
        
        // Sort: directories first, then alphabetically
        nodes.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        workspaceCache.put(path, nodes);
        return nodes;
      }
    } catch (_) {}
    return [];
  }

  Future<void> openFile(String path, {int? line}) async {
    try {
      final statRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace/stat?path=$path'),
      );
      final fileRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace/file?path=$path'),
      );

      final statEnvelope = jsonDecode(statRes.body);
      final fileEnvelope = jsonDecode(fileRes.body);

      if (statEnvelope["success"] == true && fileEnvelope["success"] == true) {
        final statData = statEnvelope["data"];
        final fileData = fileEnvelope["data"];

        final doc = EditorDocument(
          id: path,
          path: path,
          name: path.split('/').last,
          content: fileData["content"] ?? '',
          language: fileData["language"] ?? 'txt',
          encoding: fileData["encoding"] ?? 'utf8',
          lineCount: fileData["lineCount"] ?? 0,
          size: fileData["size"] ?? 0,
          lastModified: fileData["lastModified"] ?? '',
          readOnly: fileData["readOnly"] ?? true,
        );

        editor.open(doc);
        if (line != null) {
          doc.cursorLine = line;
        }

        // Set central selection
        _currentSelection = Selection(
          type: SelectionType.file,
          id: path,
          metadata: statData,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  void selectInspector(String id, String type) async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/inspector?id=$id&type=$type'),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final data = envelope["data"];
        SelectionType sType;
        switch (type) {
          case 'workspace':
            sType = SelectionType.file;
            break;
          case 'search':
            sType = SelectionType.searchResult;
            break;
          case 'workflow':
            sType = SelectionType.workflow;
            break;
          case 'architecture':
            sType = SelectionType.architectureNode;
            break;
          default:
            sType = SelectionType.file;
        }

        _currentSelection = Selection(
          type: sType,
          id: id,
          metadata: Map<String, dynamic>.from(data),
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  void selectArchitectureNode(String id) {
    selectInspector(id, "architecture");
  }

  void revealInExplorer(String path) {
    explorer.select(path);
    explorer.focus(path);
    notifyListeners();
  }

  void triggerAgentWorkflow() async {
    _agentWorkflowStatus = 'Running (Planning)...';
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('http://localhost:$_serverPort/api/run'));
      final data = jsonDecode(res.body);
      if (data['status'] == 'scheduled') {
        Future.delayed(const Duration(seconds: 2), () {
          _agentWorkflowStatus = 'Running (Coding)...';
          notifyListeners();
        });
        Future.delayed(const Duration(seconds: 4), () {
          _agentWorkflowStatus = 'Running (Reviewing)...';
          notifyListeners();
        });
        Future.delayed(const Duration(seconds: 6), () {
          _agentWorkflowStatus = 'Completed';
          _metrics['agentActiveSessionsCount'] = (_metrics['agentActiveSessionsCount'] ?? 0) + 1;
          notifyListeners();
        });
      }
    } catch (_) {
      _agentWorkflowStatus = 'Failed';
      notifyListeners();
    }
  }

  void _subscribeToEvents(int port) {
    try {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:$port/ws/events'),
      );
      _wsChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          final category = data['category'] ?? 'Event';
          final event = data['event'] ?? 'unknown';
          final payload = data['payload'] ?? '';
          final path = data['path'] ?? '';

          if (category == 'workspace') {
            // Watcher invalidation
            if (path.isNotEmpty) {
              workspaceCache.invalidate(path);
              reloadWorkspace();
            }
          }

          _eventLogs.insert(0, "[$category/$event] $payload");
          notifyListeners();
        },
        onError: (_) {
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (_) {}
  }
}
