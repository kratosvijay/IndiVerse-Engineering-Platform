import 'agent_context.dart';
import '../contracts/memory_provider.dart';

class AgentContextResolver {
  Future<AgentContext> resolve(
      String taskId, double budget, MemoryProvider memory) async {
    return AgentContext(
        taskId: taskId,
        budgetLimit: budget,
        isCancelled: false,
        memory: memory);
  }
}
