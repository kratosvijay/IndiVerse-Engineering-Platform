import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import '../controllers/chat_controller.dart';
import 'tool_permission_dialog.dart';

class ToolCallWidget extends StatefulWidget {
  final ToolCallState toolCall;
  final ChatController controller;

  const ToolCallWidget({
    super.key,
    required this.toolCall,
    required this.controller,
  });

  @override
  State<ToolCallWidget> createState() => _ToolCallWidgetState();
}

class _ToolCallWidgetState extends State<ToolCallWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.toolCall.status;
    Color statusColor;
    IconData statusIcon;
    Widget? trailingWidget;

    switch (status) {
      case ToolCallStatus.pendingPermission:
        statusColor = Colors.amber;
        statusIcon = Icons.security;
        trailingWidget = ElevatedButton(
          onPressed: _showPermissionDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Authorize'),
        );
        break;
      case ToolCallStatus.running:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.sync;
        trailingWidget = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        );
        break;
      case ToolCallStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ToolCallStatus.failed:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
    }

    final argumentsJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.toolCall.arguments);
    final outputText = widget.toolCall.result?.output.displayText ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border.all(
          color: status == ToolCallStatus.pendingPermission
              ? Colors.amber.withValues(alpha: 0.5)
              : const Color(0xFF333333),
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16.0,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(width: 6.0),
                  Icon(statusIcon, size: 16.0, color: statusColor),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tool: ${widget.toolCall.toolName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.toolCall.progressMessage != null)
                          Text(
                            widget.toolCall.progressMessage!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailingWidget != null) ...[
                    const SizedBox(width: 8),
                    trailingWidget,
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Color(0xFF333333), height: 1),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ARGUMENTS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    child: Text(
                      argumentsJson,
                      style: const TextStyle(
                        color: Color(0xFF9CDCFE),
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                  if (outputText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'OUTPUT',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          outputText,
                          style: const TextStyle(
                            color: Color(0xFFCE9178),
                            fontFamily: 'monospace',
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (widget.toolCall.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'ERROR',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C1E1E),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: Text(
                        widget.toolCall.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'monospace',
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPermissionDialog() async {
    final decision = await showDialog<PermissionDecision>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ToolPermissionDialog(toolCall: widget.toolCall),
    );

    if (decision != null) {
      await widget.controller.submitPermissionDecision(
        widget.toolCall.toolCallId,
        decision,
      );
    }
  }
}
