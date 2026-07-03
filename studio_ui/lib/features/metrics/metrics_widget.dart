import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class MetricsWidget extends StatelessWidget {
  final StudioState state;

  const MetricsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Performance Metrics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live instrumentation values captured from the running Platform SDK core.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  'Workspace Files',
                  '${state.metrics['workspaceFilesCount'] ?? 0}',
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Knowledge Chunks',
                  '${state.metrics['knowledgeChunksCount'] ?? 0}',
                  Colors.green,
                ),
                _buildMetricCard(
                  'Agent active Sessions',
                  '${state.metrics['agentActiveSessionsCount'] ?? 0}',
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Exposed Tools count',
                  '${state.metrics['registeredToolsCount'] ?? 0}',
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Avg API Latency',
                  '${state.metrics['averageApiLatencyMs'] ?? 0} ms',
                  Colors.teal,
                ),
                _buildMetricCard(
                  'Diagnostics warnings',
                  '${state.metrics['activeDiagnosticsWarningCount'] ?? 0}',
                  Colors.red,
                ),
              ],
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
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const Spacer(),
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
}
