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

  @override
  void initState() {
    super.initState();
    _connectToBackend();
  }

  void _connectToBackend() async {
    // Dynamically check ports
    for (int port = 8080; port <= 8180; port++) {
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

      setState(() {
        _health = Map<String, String>.from(jsonDecode(hRes.body));
        _features = Map<String, bool>.from(jsonDecode(fRes.body));
        _metrics = Map<String, dynamic>.from(jsonDecode(mRes.body));
      });
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
          setState(() {
            _eventLogs.insert(0, "[${data['type']}] ${data['payload']}");
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
                child: const Text(
                  'v0.7.0',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA78BFA)),
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
          const Text(
            'Workspace Explorer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan active workspace directories and identify project structures.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCard(
                  'Active Project',
                  'indiverse-engineering-platform',
                  Icons.folder_open,
                  'Flutter / Dart Framework detected.',
                ),
                _buildCard(
                  'Git Configuration',
                  'Branch: main',
                  Icons.commit,
                  'Commit history tracking active.',
                ),
              ],
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
                        title: Text(item['file'] ?? ''),
                        subtitle: Text(item['snippet'] ?? ''),
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

  Widget _buildCard(String title, String value, IconData icon, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C284D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: Colors.white30),
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
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INSPECTOR',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No active execution segment selected.',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
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
