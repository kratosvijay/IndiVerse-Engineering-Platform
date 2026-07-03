import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const StudioApp());
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndiVerse Studio',
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
  String _activeTab = 'Workspace';
  int _serverPort = 8080;
  bool _isConnected = false;
  Map<String, String> _health = {};
  Map<String, dynamic> _metrics = {};
  Map<String, bool> _features = {};
  final List<String> _eventLogs = [];
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String _agentWorkflowStatus = 'Idle';
  WebSocketChannel? _wsChannel;

  String _version = "v1.0.1";
  Map<String, dynamic>? _selectedItem;
  String? _selectedItemType;
  List<dynamic> _workspaceFiles = [];
  List<dynamic> _architectureNodes = [];
  String _activeProject = "indiverse-engineering-platform";
  String _branchName = "main";

  @override
  void initState() {
    super.initState();
    _connectToBackend();
  }

  void _connectToBackend() async {
    // Check preferred port 18080 first, then standard ports
    final portsToCheck = [18080];
    for (int p = 8080; p <= 8180; p++) {
      portsToCheck.add(p);
    }

    for (int port in portsToCheck) {
      try {
        final res = await http
            .get(Uri.parse('http://localhost:$port/api/health'))
            .timeout(const Duration(seconds: 1));
        if (res.statusCode == 200) {
          setState(() {
            _serverPort = port;
            _isConnected = true;
          });
          _fetchInitialData();
          _subscribeToEvents(port);
          break;
        }
      } catch (_) {
        // Continue hunting
      }
    }
  }

  void _fetchInitialData() async {
    try {
      final hRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/health'),
      );
      final fRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/features'),
      );
      final mRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/metrics'),
      );
      final wRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace'),
      );
      final vRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/version'),
      );

      final wJson = jsonDecode(wRes.body);
      final vJson = jsonDecode(vRes.body);

      setState(() {
        _health = Map<String, String>.from(jsonDecode(hRes.body));
        _features = Map<String, bool>.from(jsonDecode(fRes.body));
        _metrics = Map<String, dynamic>.from(jsonDecode(mRes.body));
        _version = vJson['data']['platform'] ?? 'v1.0.1';
        _workspaceFiles = wJson['data']['files'] ?? [];
        _activeProject = wJson['data']['activeProject'] ?? 'indiverse-engineering-platform';
        _branchName = wJson['data']['branch'] ?? 'main';
      });

      _fetchArchitecture();
    } catch (_) {}
  }

  void _fetchArchitecture() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/architecture'),
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        setState(() {
          _architectureNodes = data["data"]["nodes"] ?? [];
        });
      }
    } catch (_) {}
  }

  void _selectItem(Map<String, dynamic> item, String type) async {
    try {
      final id = type == "workspace" ? (item["path"] ?? "") : (item["file"] ?? item["id"] ?? "");
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/inspector?id=$id&type=$type'),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        setState(() {
          _selectedItem = Map<String, dynamic>.from(envelope["data"]);
          _selectedItemType = type;
        });
      }
    } catch (_) {}
  }

  void _subscribeToEvents(int port) {
    try {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:$port/ws/events'),
      );
      _wsChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          final type = data['type'] ?? data['event'] ?? 'Event';
          final payload = data['payload'] ?? '';
          setState(() {
            _eventLogs.insert(0, "[$type] ${_formatEventPayload(type, payload)}");
          });
        },
        onError: (_) {
          setState(() => _isConnected = false);
        },
        onDone: () {
          setState(() => _isConnected = false);
        },
      );
    } catch (_) {}
  }

  String _formatEventPayload(String type, String payload) {
    switch (type) {
      case 'WorkspaceRefreshing':
        return 'Workspace Refreshing • Scanning project...';
      case 'WorkspaceReady':
        return 'Workspace Ready • Project parsed successfully';
      case 'WorkspaceOpened':
        return 'Workspace Opened • Initializing scanner';
      case 'WorkspaceClosed':
        return 'Workspace Closed';
      case 'PluginLoaded':
        return 'Plugin Loaded • Loading capability registries';
      case 'PluginActivated':
        return 'Plugin Activated • Engine fully operational';
      default:
        return payload;
    }
  }

  void _executeSearch(String query) async {
    if (query.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/search?q=$query'),
      );
      final data = jsonDecode(res.body);
      setState(() {
        _searchResults = data['results'] ?? [];
      });
    } catch (_) {}
  }

  void _triggerAgentWorkflow() async {
    setState(() => _agentWorkflowStatus = 'Running (Planning)...');
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/run'),
      );
      final data = jsonDecode(res.body);
      if (data['status'] == 'scheduled') {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() => _agentWorkflowStatus = 'Running (Coding)...');
        });
        Future.delayed(const Duration(seconds: 4), () {
          setState(() => _agentWorkflowStatus = 'Running (Reviewing)...');
        });
        Future.delayed(const Duration(seconds: 6), () {
          setState(() {
            _agentWorkflowStatus = 'Completed';
            _metrics['agentActiveSessionsCount'] =
                (_metrics['agentActiveSessionsCount'] ?? 0) + 1;
          });
        });
      }
    } catch (_) {
      setState(() => _agentWorkflowStatus = 'Failed');
    }
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildMainWorkspace()),
                _buildInspector(),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF16132A),
        border: Border(bottom: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.blur_on, color: Color(0xFF8B5CF6), size: 28),
              const SizedBox(width: 10),
              const Text(
                'IndiVerse Studio',
                style: TextStyle(
                  fontSize: 18,
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
                  _version,
                  style: const TextStyle(fontSize: 10, color: Color(0xFFA78BFA)),
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
                  final active = _activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextButton(
                      onPressed: () => setState(() => _activeTab = tab),
                      style: TextButton.styleFrom(
                        foregroundColor: active ? Colors.white : Colors.white54,
                        backgroundColor: active
                            ? const Color(0xFF2E1065)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(tab),
                    ),
                  );
                }).toList(),
          ),
          Row(
            children: [
              Icon(
                _isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _isConnected ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                _isConnected ? 'Connected (:$_serverPort)' : 'Disconnected',
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF110E22),
        border: Border(right: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PLATFORM HEALTH',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._health.entries.map((e) => _buildHealthTile(e.key, e.value)),
          const SizedBox(height: 24),
          const Text(
            'FEATURE FLAGS',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ..._features.entries.map((e) => _buildFeatureTile(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildHealthTile(String name, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'ready':
        color = Colors.green;
        break;
      case 'indexing':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const Spacer(),
          Text(status, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String name, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWorkspace() {
    switch (_activeTab) {
      case 'Workspace':
        return _buildWorkspacePanel();
      case 'Search':
        return _buildSearchPanel();
      case 'Agents':
        return _buildAgentsPanel();
      case 'Architecture':
        return _buildArchitecturePanel();
      case 'Metrics':
        return _buildMetricsPanel();
      case 'Diagnostics':
        return _buildDiagnosticsPanel();
      default:
        return const Center(child: Text('Panel Not Implemented'));
    }
  }

  Widget _buildWorkspacePanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workspace Explorer',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Project: $_activeProject  •  Branch: $_branchName',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B4B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _workspaceFiles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _workspaceFiles.length,
                    itemBuilder: (context, index) {
                      final file = _workspaceFiles[index];
                      final name = file["name"] as String? ?? "";
                      final path = file["path"] as String? ?? "";
                      final sizeKb = ((file["size"] as int? ?? 0) / 1024).toStringAsFixed(1);

                      return ListTile(
                        leading: const Icon(Icons.description, color: Color(0xFFA78BFA), size: 18),
                        title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(path, style: const TextStyle(fontSize: 11, color: Colors.white30)),
                        trailing: Text("$sizeKb KB", style: const TextStyle(fontSize: 11, color: Colors.white30)),
                        onTap: () {
                          _selectItem(Map<String, dynamic>.from(file), "workspace");
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitecturePanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Architecture Explorer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Visualize the system layers, contracts, health states, and inter-component dependencies.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _architectureNodes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _architectureNodes.length,
                    itemBuilder: (context, index) {
                      final node = _architectureNodes[index];
                      final label = node["label"] as String? ?? "";
                      final layer = node["layer"] as String? ?? "";

                      return InkWell(
                        onTap: () {
                          _selectItem(Map<String, dynamic>.from(node), "architecture");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B4B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF312E81)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF311042),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(layer, style: const TextStyle(fontSize: 10, color: Color(0xFFF472B6))),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 14),
                                  SizedBox(width: 6),
                                  Text("Healthy", style: TextStyle(fontSize: 12, color: Colors.green)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semantic Code Search',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Ask questions or search codebase...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _executeSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      'No search matches found.',
                      style: TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.search, color: Color(0xFF8B5CF6), size: 18),
                        title: Text(item['file'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA78BFA))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['snippet'] ?? '', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text("Line ${item['lineNumber']} • Score: ${item['score']}", style: const TextStyle(fontSize: 11, color: Colors.white30)),
                          ],
                        ),
                        onTap: () {
                          _selectItem(Map<String, dynamic>.from(item), "search");
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsPanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agent Workflow Monitor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Orchestrator state: $_agentWorkflowStatus',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _triggerAgentWorkflow,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Workflow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131024),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C284D)),
              ),
              child: _eventLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No active logs yet.',
                        style: TextStyle(color: Colors.white30),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _eventLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _eventLogs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFFC084FC),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrics Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Workspace Files',
                  '${_metrics['workspaceFilesCount'] ?? 0}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Knowledge Chunks',
                  '${_metrics['knowledgeChunksCount'] ?? 0}',
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Agent Active Sessions',
                  '${_metrics['agentActiveSessionsCount'] ?? 0}',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsPanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Diagnostics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131024),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C284D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EVENT PIPELINE TIMELINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white30,
                    ),
                  ),
                  const Divider(color: Color(0xFF2C284D)),
                  Expanded(
                    child: ListView(
                      children: const [
                        ListTile(
                          title: Text(
                            'Workspace indexer scanning directories completed.',
                          ),
                          subtitle: Text('Time: 19:42:01'),
                          leading: Icon(Icons.done_all, color: Colors.green),
                        ),
                        ListTile(
                          title: Text('Knowledge Engine embeddings generated.'),
                          subtitle: Text('Time: 19:42:02'),
                          leading: Icon(Icons.memory, color: Colors.purple),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMetricCard(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C284D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF110E22),
        border: Border(left: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INSPECTOR',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedItem == null)
                const Text(
                  'No active execution segment selected.',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                )
              else
                ..._buildInspectorDetails(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInspectorDetails() {
    if (_selectedItem == null) return [];
    final details = _selectedItem!["details"] as Map<String, dynamic>? ?? {};
    final type = _selectedItemType;

    final widgets = <Widget>[];

    if (type == "workspace") {
      widgets.addAll([
        Text(details["path"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA78BFA))),
        const Divider(color: Color(0xFF2C284D), height: 24),
        _buildInspectorRow("Size", details["size"] ?? ""),
        _buildInspectorRow("Lines", "${details["lines"] ?? 0}"),
        _buildInspectorRow("Language", details["language"] ?? ""),
        _buildInspectorRow("Git Status", details["gitStatus"] ?? ""),
        _buildInspectorRow("Indexed", details["indexed"] == true ? "Yes" : "No"),
        _buildInspectorRow("Embeddings", details["embeddings"] ?? ""),
        const SizedBox(height: 16),
        const Text("Symbols", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 6),
        ...((details["symbols"] as List? ?? []).map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(s.toString(), style: const TextStyle(fontSize: 11, color: Colors.white30)),
        ))),
      ]);
    } else if (type == "search") {
      widgets.addAll([
        Text(details["file"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA78BFA))),
        const Divider(color: Color(0xFF2C284D), height: 24),
        _buildInspectorRow("Score", details["score"] ?? ""),
        _buildInspectorRow("Match Reason", details["reason"] ?? ""),
        const SizedBox(height: 16),
        const Text("Snippet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
          child: Text(details["snippet"] ?? "", style: const TextStyle(fontFamily: "monospace", fontSize: 11, color: Colors.white70)),
        ),
      ]);
    } else if (type == "workflow") {
      widgets.addAll([
        Text(details["id"] ?? "Workflow Agent", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA78BFA))),
        const Divider(color: Color(0xFF2C284D), height: 24),
        _buildInspectorRow("Status", details["state"] ?? ""),
        _buildInspectorRow("Duration", details["duration"] ?? ""),
        _buildInspectorRow("Tokens", "${details["tokens"] ?? 0}"),
        _buildInspectorRow("Cost", details["cost"] ?? ""),
        _buildInspectorRow("Current Step", details["currentStep"] ?? ""),
      ]);
    } else if (type == "architecture") {
      widgets.addAll([
        Text(details["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA78BFA))),
        const Divider(color: Color(0xFF2C284D), height: 24),
        _buildInspectorRow("Health Status", details["health"] ?? ""),
        _buildInspectorRow("Latency", details["latency"] ?? ""),
        _buildInspectorRow("State", details["status"] ?? ""),
      ]);
    }

    return widgets;
  }

  Widget _buildInspectorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16132A),
        border: Border(top: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Status: Idle',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          Row(
            children: [
              const Text(
                'Tokens Consumed: 0',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(width: 16),
              const Text(
                'Session Cost: \$0.00',
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
                'Local Server Online',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
