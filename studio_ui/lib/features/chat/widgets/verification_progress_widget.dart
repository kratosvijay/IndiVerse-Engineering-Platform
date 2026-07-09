import 'dart:io';
import 'package:flutter/material.dart';

class VerificationProgressWidget extends StatelessWidget {
  final String activeStage;
  final String statusText;
  final int retryAttempt;
  final int maxRetries;
  final List<String> historyLog;

  const VerificationProgressWidget({
    super.key,
    required this.activeStage,
    required this.statusText,
    required this.retryAttempt,
    required this.maxRetries,
    required this.historyLog,
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
              Text(
                activeStage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Attempt $retryAttempt/$maxRetries',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: Platform.environment.containsKey('FLUTTER_TEST')
                      ? 0.5
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orangeAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          const Text(
            'Timeline Execution history:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...historyLog.map((log) {
            final isPass =
                log.contains('Passed') ||
                log.contains('Completed') ||
                log.contains('✔');
            final isFail = log.contains('Failed') || log.contains('✖');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: [
                  Icon(
                    isPass
                        ? Icons.check_circle_outline
                        : isFail
                        ? Icons.error_outline
                        : Icons.loop_outlined,
                    size: 13,
                    color: isPass
                        ? Colors.greenAccent
                        : isFail
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log,
                      style: TextStyle(
                        color: isPass
                            ? Colors.greenAccent
                            : isFail
                            ? Colors.redAccent
                            : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
