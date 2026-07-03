import '../models/ai_request.dart';
import '../models/execution_result.dart';

abstract class RuntimeCore {
  Future<ExecutionResult> execute(AIRequest request);
  Stream<String> executeStream(AIRequest request);
}
