import 'package:flutter/material.dart';

class ReviewDashboardWidget extends StatelessWidget {
  final double architectureScore;
  final double securityScore;
  final double performanceScore;
  final double overallConfidence;
  final int pendingApprovalsCount;
  final String complianceStatus;

  const ReviewDashboardWidget({
    super.key,
    required this.architectureScore,
    required this.securityScore,
    required this.performanceScore,
    required this.overallConfidence,
    required this.pendingApprovalsCount,
    required this.complianceStatus,
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
              const Row(
                children: [
                  Icon(Icons.gavel, size: 14, color: Colors.purpleAccent),
                  SizedBox(width: 4),
                  Text(
                    'Engineering Intelligence Review',
                    style: TextStyle(
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
                  complianceStatus.toUpperCase(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Architecture', architectureScore),
              _buildMetricColumn('Security', securityScore),
              _buildMetricColumn('Performance', performanceScore),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    size: 13,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Confidence: ${(overallConfidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    size: 13,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pending Approvals: $pendingApprovalsCount',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
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

  Widget _buildMetricColumn(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          '${score.toStringAsFixed(1)}/10.0',
          style: TextStyle(
            color: score >= 8.5 ? Colors.greenAccent : Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
