import 'package:flutter/material.dart';

class ClusterDashboardWidget extends StatelessWidget {
  final String clusterId;
  final String status;
  final int workersCount;
  final int runningJobs;
  final double averageCpu;
  final double averageMemory;
  final int activeLeases;
  final String knowledgeSyncStatus;

  const ClusterDashboardWidget({
    super.key,
    required this.clusterId,
    required this.status,
    required this.workersCount,
    required this.runningJobs,
    required this.averageCpu,
    required this.averageMemory,
    required this.activeLeases,
    required this.knowledgeSyncStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub, size: 14, color: Colors.cyanAccent),
                  const SizedBox(width: 4),
                  Text(
                    clusterId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Workers: $workersCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Running Jobs: $runningJobs',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg CPU: ${(averageCpu).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Avg RAM: ${(averageMemory).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_person,
                    size: 13,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active Leases: $activeLeases',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.sync, size: 13, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Knowledge Sync: $knowledgeSyncStatus',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
