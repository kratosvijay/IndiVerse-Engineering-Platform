import 'dart:async';
import '../../models/tool_call_models.dart';
import '../../prompt/prompt_pipeline.dart';
import '../../../../platform_sdk/platform_sdk.dart';

class ToolExecutionContext {
  final String workspaceId;
  final String conversationId;
  final String requestId;
  final String providerId;
  final String modelId;
  final CancellationToken cancellationToken;
  final PlatformSDK sdk;
  final Map<String, Object?> metadata;

  const ToolExecutionContext({
    required this.workspaceId,
    required this.conversationId,
    required this.requestId,
    required this.providerId,
    required this.modelId,
    required this.cancellationToken,
    required this.sdk,
    this.metadata = const {},
  });
}

abstract class ToolHandler {
  ToolDescriptor get descriptor;
  Future<ToolCallResult> execute(ToolCallRequest request, ToolExecutionContext context);
}
