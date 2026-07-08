import 'dart:async';
import '../../models/tool_call_models.dart';

import 'tool_registry.dart';
import 'tool_handler.dart';
import 'permission_store.dart';
import 'workspace_snapshot_service.dart';
import 'tool_audit_service.dart';

class ToolExecutionService {
  final ToolRegistry registry;
  final ToolPermissionStore permissionStore;
  final WorkspaceSnapshotService snapshotService = WorkspaceSnapshotService();
  final ToolAuditService auditService = ToolAuditService();

  final Map<String, Completer<PermissionDecision>> _pendingPermissions = {};
  final Map<String, ToolExecutionMetrics> _metrics = {};
  final Map<String, int> _requestDepths = {};

  ToolExecutionService({
    required this.registry,
    required this.permissionStore,
  });

  Map<String, ToolExecutionMetrics> get metrics => _metrics;

  Completer<PermissionDecision>? getPendingPermission(String toolCallId) {
    return _pendingPermissions[toolCallId];
  }

  void resolvePermission(String toolCallId, PermissionDecision decision) {
    final completer = _pendingPermissions.remove(toolCallId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(decision);
    }
  }

  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final tool = registry.getTool(request.toolName);

    // Compute depth: depth = parent.depth + 1
    int depth = 0;
    if (request.parentToolCallId != null) {
      final parentDepth = _requestDepths[request.parentToolCallId!];
      if (parentDepth != null) {
        depth = parentDepth + 1;
      }
    }
    _requestDepths[request.toolCallId] = depth;

    final requestWithDepth = ToolCallRequest(
      toolCallId: request.toolCallId,
      toolName: request.toolName,
      arguments: request.arguments,
      parentToolCallId: request.parentToolCallId,
      depth: depth,
    );

    if (tool == null) {
      final result = ToolCallResult(
        success: false,
        output: ToolOutput(
            displayText: 'Tool "${request.toolName}" not registered.'),
        duration: stopwatch.elapsed,
        errorCode: 'TOOL_NOT_FOUND',
      );
      await _audit(requestWithDepth, context, result, 'none',
          stopwatch.elapsedMilliseconds);
      return result;
    }

    final toolId = tool.descriptor.id;
    _initializeMetrics(toolId);

    String permissionUsed = 'none';

    // 1. Permission checks
    if (tool.descriptor.requiresPermission) {
      final persistentDecision = permissionStore.getDecision(toolId);
      PermissionDecision decision;

      if (persistentDecision != null) {
        decision = persistentDecision;
        permissionUsed = 'persistent:${decision.name}';
      } else {
        final completer = Completer<PermissionDecision>();
        _pendingPermissions[request.toolCallId] = completer;

        // Will be completed externally by calling resolvePermission
        decision = await completer.future.timeout(
          const Duration(minutes: 5),
          onTimeout: () => PermissionDecision.deny,
        );
        permissionUsed = decision.name;
      }

      if (decision == PermissionDecision.deny ||
          decision == PermissionDecision.denyAlways) {
        if (decision == PermissionDecision.denyAlways) {
          permissionStore.saveDecision(toolId, PermissionDecision.denyAlways);
        }
        _recordMetrics(toolId, success: false, cancellation: false);
        final result = ToolCallResult(
          success: false,
          output: const ToolOutput(displayText: 'Permission denied by user.'),
          duration: stopwatch.elapsed,
          errorCode: 'PERMISSION_DENIED',
        );
        await _audit(requestWithDepth, context, result, permissionUsed,
            stopwatch.elapsedMilliseconds);
        return result;
      } else if (decision == PermissionDecision.allowAlways) {
        permissionStore.saveDecision(toolId, PermissionDecision.allowAlways);
      }
    }

    // 2. Capture Snapshot if the tool modifies the workspace
    final String? pathParam = request.arguments['path'] as String? ??
        request.arguments['filePath'] as String?;
    if (pathParam != null && tool.descriptor.modifiesWorkspace) {
      final snapshot =
          await snapshotService.captureSnapshot(pathParam, context.requestId);
      if (snapshot != null) {
        _metrics[toolId]?.snapshotCount++;
      }
    }

    // 3. Cancellation check
    if (context.cancellationToken.isCancelled) {
      _recordMetrics(toolId, success: false, cancellation: true);
      final result = ToolCallResult(
        success: false,
        output: const ToolOutput(displayText: 'Execution cancelled.'),
        duration: stopwatch.elapsed,
        errorCode: 'CANCELLED',
      );
      await _audit(requestWithDepth, context, result, permissionUsed,
          stopwatch.elapsedMilliseconds);
      return result;
    }

    // 4. Execution with Timeout & Retries
    ToolCallResult result = const ToolCallResult(
      success: false,
      output: ToolOutput(displayText: 'Execution timed out.'),
      duration: Duration.zero,
      errorCode: 'TIMEOUT',
    );

    int attempts = 0;
    const maxRetries = 2;

    while (attempts <= maxRetries) {
      if (context.cancellationToken.isCancelled) {
        _recordMetrics(toolId, success: false, cancellation: true);
        final cancelResult = ToolCallResult(
          success: false,
          output: const ToolOutput(displayText: 'Execution cancelled.'),
          duration: stopwatch.elapsed,
          errorCode: 'CANCELLED',
        );
        await _audit(requestWithDepth, context, cancelResult, permissionUsed,
            stopwatch.elapsedMilliseconds);
        return cancelResult;
      }

      attempts++;
      try {
        final future = tool.execute(requestWithDepth, context);
        result = await future.timeout(tool.descriptor.timeout);
        if (result.success) break;
      } catch (e) {
        result = ToolCallResult(
          success: false,
          output: ToolOutput(displayText: 'Execution error: $e'),
          duration: stopwatch.elapsed,
          errorCode: 'EXECUTION_ERROR',
        );
      }
    }

    final durationMs = stopwatch.elapsedMilliseconds;
    _recordMetrics(toolId,
        success: result.success, cancellation: false, durationMs: durationMs);
    await _audit(requestWithDepth, context, result, permissionUsed, durationMs);

    return result;
  }

  Future<void> _audit(
    ToolCallRequest request,
    ToolExecutionContext context,
    ToolCallResult result,
    String permission,
    int durationMs,
  ) async {
    final record = ToolAuditRecord(
      timestamp: DateTime.now(),
      conversationId: context.conversationId,
      requestId: context.requestId,
      toolCallId: request.toolCallId,
      parentToolCallId: request.parentToolCallId,
      tool: request.toolName,
      durationMs: durationMs,
      success: result.success,
      permission: permission,
      workspaceId: context.workspaceId,
      providerId: context.providerId,
      modelId: context.modelId,
      errorMessage: result.success ? null : (result.errorCode ?? 'ERROR'),
    );

    await auditService.log(record);
    final toolId = registry.getTool(request.toolName)?.descriptor.id;
    if (toolId != null) {
      _metrics[toolId]?.auditEntries++;
    }
  }

  void _initializeMetrics(String toolId) {
    _metrics.putIfAbsent(toolId, () => ToolExecutionMetrics());
  }

  void _recordMetrics(String toolId,
      {required bool success, required bool cancellation, int durationMs = 0}) {
    final m = _metrics[toolId]!;
    m.executions++;
    m.totalDurationMs += durationMs;
    if (!success) {
      if (cancellation) {
        m.cancellations++;
      } else {
        m.failures++;
      }
    }
  }
}

class ToolExecutionMetrics {
  int executions = 0;
  int failures = 0;
  int cancellations = 0;
  int totalDurationMs = 0;
  int snapshotCount = 0;
  int auditEntries = 0;

  double get averageLatency =>
      executions == 0 ? 0.0 : totalDurationMs / executions;

  Map<String, dynamic> toJson() => {
        'executions': executions,
        'failures': failures,
        'cancellations': cancellations,
        'averageLatency': averageLatency,
        'snapshotCount': snapshotCount,
        'auditEntries': auditEntries,
      };
}
