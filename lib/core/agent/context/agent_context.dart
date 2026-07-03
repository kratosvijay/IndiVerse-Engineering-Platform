import '../contracts/memory_provider.dart';

class AgentContext {
  final String taskId;
  final double budgetLimit;
  final bool isCancelled;
  final MemoryProvider memory;

  const AgentContext({
    required this.taskId,
    required this.budgetLimit,
    required this.isCancelled,
    required this.memory,
  });
}
