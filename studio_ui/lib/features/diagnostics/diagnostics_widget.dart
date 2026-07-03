import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class DiagnosticsWidget extends StatelessWidget {
  final StudioState state;

  const DiagnosticsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Health Diagnostics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check operational states of background services, configurations, and API connections.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildHealthStatusRow('Runtime Engine Pipeline', state.health['Runtime'] ?? 'ready'),
          _buildHealthStatusRow('Workspace Context Scanner', state.health['Workspace'] ?? 'ready'),
          _buildHealthStatusRow('Knowledge & Vector Database', state.health['Knowledge'] ?? 'ready'),
          _buildHealthStatusRow('Plugin registry Services', state.health['Plugin'] ?? 'ready'),
          _buildHealthStatusRow('Studio REST API Bindings', state.health['Studio'] ?? 'ready'),
        ],
      ),
    );
  }

  Widget _buildHealthStatusRow(String service, String status) {
    final isOk = status.toLowerCase() == 'ready' || status.toLowerCase() == 'healthy';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C284D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Row(
            children: [
              Icon(isOk ? Icons.check_circle : Icons.error, color: isOk ? Colors.green : Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: isOk ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
