import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';

class ToolPermissionDialog extends StatelessWidget {
  final ToolCallState toolCall;

  const ToolPermissionDialog({super.key, required this.toolCall});

  @override
  Widget build(BuildContext context) {
    final argumentsJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(toolCall.arguments);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Tool Permission Requested',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF333333), height: 24),
            Text(
              'The AI model is requesting permission to execute the following tool:',
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF252526),
                border: Border.all(color: const Color(0xFF3C3C3C)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_circle,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    toolCall.toolName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Arguments:',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF2D2D2D)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  argumentsJson,
                  style: const TextStyle(
                    color: Color(0xFF85C46C),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, PermissionDecision.deny),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Deny'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, PermissionDecision.allowOnce),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E639C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Allow Once'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, PermissionDecision.allowAlways),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Allow Always'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
