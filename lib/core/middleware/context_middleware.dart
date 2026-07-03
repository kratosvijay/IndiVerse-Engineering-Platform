import 'middleware.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

class ContextMiddleware implements Middleware {
  final String additionalContext;
  ContextMiddleware(this.additionalContext);

  @override
  Future<AIResponse> next(AIRequest request,
      Future<AIResponse> Function(AIRequest) nextHandler) async {
    final aggregatedContext = request.context.isNotEmpty
        ? "${request.context}\n$additionalContext"
        : additionalContext;

    final updatedRequest = AIRequest(
      prompt: request.prompt,
      context: aggregatedContext,
      modelName: request.modelName,
      temperature: request.temperature,
      maxTokens: request.maxTokens,
      streaming: request.streaming,
      tools: request.tools,
      metadata: request.metadata,
    );

    return await nextHandler(updatedRequest);
  }
}
