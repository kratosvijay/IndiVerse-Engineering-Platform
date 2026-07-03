import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/context/agent_context.dart';
import 'package:indiverse_developer_platform/core/agent/context/context_resolver.dart';
import 'package:indiverse_developer_platform/core/agent/memory/task_memory.dart';

void main() {
  group('AgentContext Tests', () {
    test('ContextResolver resolves valid context payload', () async {
      final resolver = AgentContextResolver();
      final memory = TaskMemory();
      final AgentContext context =
          await resolver.resolve('task-1', 100.0, memory);

      expect(context.taskId, equals('task-1'));
      expect(context.budgetLimit, equals(100.0));
      expect(context.isCancelled, isFalse);
    });
  });
}
