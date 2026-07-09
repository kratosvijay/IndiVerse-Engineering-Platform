import 'package:flutter/material.dart';

class PipelineDashboardWidget extends StatelessWidget {
  final String activePipeline;
  final List<String> stages;
  final String deploymentTarget;
  final double availability;
  final double crashRate;
  final double healthScore;
  final String approvalStatus;
  final bool rollbackAvailable;

  const PipelineDashboardWidget({
    super.key,
    required this.activePipeline,
    required this.stages,
    required this.deploymentTarget,
    required this.availability,
    required this.crashRate,
    required this.healthScore,
    required this.approvalStatus,
    required this.rollbackAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final hasWarning = healthScore < 7.0;

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
                  const Icon(
                    Icons.rocket_launch,
                    size: 14,
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activePipeline,
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
                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  deploymentTarget.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pipeline Stages:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: stages.map((stage) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 10,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stage,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability: ${(availability * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Crash Rate: ${crashRate.toStringAsFixed(2)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasWarning
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score: ${healthScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: hasWarning
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    approvalStatus == 'Approved'
                        ? Icons.verified
                        : Icons.lock_outline,
                    size: 13,
                    color: approvalStatus == 'Approved'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Approval: $approvalStatus',
                    style: TextStyle(
                      color: approvalStatus == 'Approved'
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (rollbackAvailable)
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 13,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rollback Ready',
                      style: TextStyle(
                        color: Colors.blueAccent.withValues(alpha: 0.8),
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
