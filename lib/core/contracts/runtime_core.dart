import '../models/ai_request.dart';
import '../models/execution_result.dart';
import '../models/ai_chunk.dart';

abstract class RuntimeCore {
  Future<ExecutionResult> execute(AIRequest request);
  Stream<AIChunk> executeStream(AIRequest request);
}
