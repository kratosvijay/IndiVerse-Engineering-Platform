import 'package:flutter/material.dart';

class GitDashboardWidget extends StatelessWidget {
  final String activeBranch;
  final String baseBranch;
  final String purpose;
  final String latestCommitHash;
  final String latestCommitMsg;
  final int filesChangedCount;
  final bool passesGates;
  final bool hasPRDraft;

  const GitDashboardWidget({
    super.key,
    required this.activeBranch,
    required this.baseBranch,
    required this.purpose,
    required this.latestCommitHash,
    required this.latestCommitMsg,
    required this.filesChangedCount,
    required this.passesGates,
    required this.hasPRDraft,
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
                  const Icon(
                    Icons.call_split,
                    size: 14,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeBranch,
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
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  purpose.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Base: $baseBranch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          const Text(
            'Latest Commit:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  latestCommitHash,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  latestCommitMsg,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Changed Files: $filesChangedCount',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Row(
                children: [
                  Icon(
                    passesGates ? Icons.check_circle : Icons.error,
                    size: 13,
                    color: passesGates ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    passesGates ? 'Gates Passed' : 'Gates Failed',
                    style: TextStyle(
                      color: passesGates
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasPRDraft) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF333333)),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.description, size: 14, color: Colors.greenAccent),
                SizedBox(width: 4),
                Text(
                  'Pull Request Draft generated',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
