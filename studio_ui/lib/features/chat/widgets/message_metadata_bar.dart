import 'package:flutter/material.dart';
import '../../../models/message_metadata.dart';

class MessageMetadataBar extends StatelessWidget {
  final MessageMetadata metadata;

  const MessageMetadataBar({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final List<String> parts = [];

    if (metadata.modelId != null) {
      parts.add(metadata.modelId!.toUpperCase());
    }

    if (metadata.promptTokens != null || metadata.completionTokens != null) {
      final total = metadata.totalTokens;
      parts.add('$total tokens (in:${metadata.promptTokens ?? 0}/out:${metadata.completionTokens ?? 0})');
    }

    if (metadata.latencyMs != null) {
      final seconds = (metadata.latencyMs! / 1000.0).toStringAsFixed(2);
      parts.add('${seconds}s latency');
    }

    if (metadata.ttftMs != null) {
      parts.add('ttft:${metadata.ttftMs}ms');
    }

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Text(
        parts.join('  •  '),
        style: const TextStyle(
          color: Color(0xFF858585),
          fontSize: 10.0,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
