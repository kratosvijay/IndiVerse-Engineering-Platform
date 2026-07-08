import 'dart:convert';
import 'dart:io';

class ToolAuditRecord {
  final DateTime timestamp;
  final String conversationId;
  final String requestId;
  final String toolCallId;
  final String? parentToolCallId;
  final String tool;
  final int durationMs;
  final bool success;
  final String permission;
  final String workspaceId;
  final String providerId;
  final String modelId;
  final String? errorMessage;

  const ToolAuditRecord({
    required this.timestamp,
    required this.conversationId,
    required this.requestId,
    required this.toolCallId,
    this.parentToolCallId,
    required this.tool,
    required this.durationMs,
    required this.success,
    required this.permission,
    required this.workspaceId,
    required this.providerId,
    required this.modelId,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'conversationId': conversationId,
        'requestId': requestId,
        'toolCallId': toolCallId,
        if (parentToolCallId != null) 'parentToolCallId': parentToolCallId,
        'tool': tool,
        'durationMs': durationMs,
        'success': success,
        'permission': permission,
        'workspaceId': workspaceId,
        'providerId': providerId,
        'modelId': modelId,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

class ToolAuditService {
  final String baseDir;
  final List<ToolAuditRecord> _inMemoryLogs = [];
  List<ToolAuditRecord> get inMemoryLogs => _inMemoryLogs;

  ToolAuditService({this.baseDir = '.indiverse'});

  Future<void> log(ToolAuditRecord record) async {
    _inMemoryLogs.add(record);

    try {
      final logsDir = Directory('$baseDir/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final file = File('${logsDir.path}/tool_audit.jsonl');
      final line = jsonEncode(record.toJson()) + '\n';
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // Fail-safe: continue even if file writing fails
    }
  }

  void clear() {
    _inMemoryLogs.clear();
  }
}
