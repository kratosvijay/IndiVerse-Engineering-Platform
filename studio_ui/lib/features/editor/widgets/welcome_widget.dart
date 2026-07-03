import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class WelcomeWidget extends StatefulWidget {
  final StudioState state;

  const WelcomeWidget({super.key, required this.state});

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final res = await widget.state.workbench.workspace.getIndexStatus();
    if (res.success && res.data != null) {
      if (mounted) {
        setState(() {
          _stats = res.data!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0C1B),
      padding: const EdgeInsets.all(40),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IndiVerse Studio',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Professional workbench & execution runtime engine.',
                style: TextStyle(fontSize: 13, color: Colors.white30),
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Files',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        const Text('• lib/main.dart', style: TextStyle(fontSize: 12, color: Colors.white30)),
                        const SizedBox(height: 6),
                        const Text('• lib/core/studio/server/server.dart', style: TextStyle(fontSize: 12, color: Colors.white30)),
                        const SizedBox(height: 6),
                        const Text('• docs/adr/0015-workbench-command-architecture.md', style: TextStyle(fontSize: 12, color: Colors.white30)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAction('Open Folder', 'Cmd+O'),
                        _buildQuickAction('Quick Open', 'Ctrl+P'),
                        _buildQuickAction('Command Palette', 'Cmd+Shift+P'),
                        _buildQuickAction('New File', 'Cmd+N'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131024),
                  border: Border.all(color: const Color(0xFF2C284D)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WORKSPACE STATISTICS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA78BFA)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Files Indexed', '${_stats["indexed"] ?? 0}'),
                        _buildStat('Total Symbols', '${_stats["symbols"] ?? 0}'),
                        _buildStat('Git Branch', 'main'),
                        _buildStat('Indexer State', '${_stats["indexerState"] ?? "Ready"}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, String shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFA78BFA))),
          Text(shortcut, style: const TextStyle(fontSize: 11, color: Colors.white24, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white30)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
      ],
    );
  }
}
