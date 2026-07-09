import '../../studio/services/tool_execution_service.dart';
import '../../studio/services/tool_handler.dart';
import '../../models/tool_call_models.dart';
import '../../prompt/prompt_pipeline.dart';
import '../../../../platform_sdk/platform_sdk.dart';
import 'task_step.dart';

abstract class StepTypeExecutor {
  Future<ToolCallResult> execute(
    TaskStep step,
    String workspaceId,
    String conversationId,
    String requestId,
    CancellationToken token,
  );
}

class ToolStepExecutor implements StepTypeExecutor {
  final ToolExecutionService executionService;
  final PlatformSDK sdk;

  ToolStepExecutor(this.executionService, this.sdk);

  @override
  Future<ToolCallResult> execute(
    TaskStep step,
    String workspaceId,
    String conversationId,
    String requestId,
    CancellationToken token,
  ) async {
    if (step.toolId == null) {
      return const ToolCallResult(
        success: true,
        output: ToolOutput(
            displayText: 'No tool specified', mimeType: 'text/plain'),
        duration: Duration.zero,
      );
    }

    final tool = executionService.registry.getTool(step.toolId!);
    if (tool == null) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
            displayText: 'Tool not found: ${step.toolId}',
            mimeType: 'text/plain'),
        duration: Duration.zero,
        errorCode: 'TOOL_NOT_FOUND',
      );
    }

    if (tool.descriptor.requiresPermission) {
      final decision =
          executionService.permissionStore.getDecision(step.toolId!);
      if (decision == null ||
          decision == PermissionDecision.deny ||
          decision == PermissionDecision.denyAlways) {
        return const ToolCallResult(
          success: false,
          output: ToolOutput(
              displayText: 'Permission required', mimeType: 'text/plain'),
          duration: Duration.zero,
          errorCode: 'PERMISSION_REQUIRED',
        );
      }
    }

    final request = ToolCallRequest(
      toolCallId: 'step-${step.id}',
      toolName: step.toolId!,
      arguments: step.arguments ?? {},
    );

    final context = ToolExecutionContext(
      workspaceId: workspaceId,
      conversationId: conversationId,
      requestId: requestId,
      providerId: 'agent-planner',
      modelId: 'default',
      cancellationToken: token,
      sdk: sdk,
    );

    return executionService.execute(request, context);
  }
}

class StepExecutor {
  final Map<StepType, StepTypeExecutor> executors = {};

  StepExecutor(ToolExecutionService executionService, PlatformSDK sdk) {
    executors[StepType.tool] = ToolStepExecutor(executionService, sdk);
  }

  void registerExecutor(StepType type, StepTypeExecutor executor) {
    executors[type] = executor;
  }

  Future<ToolCallResult> execute(
    TaskStep step,
    String workspaceId,
    String conversationId,
    String requestId,
    CancellationToken token,
  ) async {
    final executor = executors[step.type];
    if (executor == null) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
            displayText: 'Executor not implemented for ${step.type}',
            mimeType: 'text/plain'),
        duration: Duration.zero,
        errorCode: 'UNIMPLEMENTED_STEP_TYPE',
      );
    }
    return executor.execute(
        step, workspaceId, conversationId, requestId, token);
  }
}
