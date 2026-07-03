import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/memory/agent_memory.dart';
import 'package:indiverse_developer_platform/core/agent/memory/workspace_memory.dart';
import 'package:indiverse_developer_platform/core/agent/memory/task_memory.dart';

void main() {
  group('AgentMemory Tests', () {
    test('TaskMemory local scope operations', () async {
      final memory = TaskMemory();
      await memory.save('key', 'val');
      expect(await memory.retrieve('key'), equals('val'));
      await memory.clear();
      expect(await memory.retrieve('key'), isNull);
    });

    test('WorkspaceMemory persistent mock scope operations', () async {
      final memory = WorkspaceMemory();
      await memory.save('key', 'val');
      expect(await memory.retrieve('key'), equals('val'));
    });

    test('AgentMemory scope operations', () async {
      final memory = AgentMemory();
      await memory.save('key', 'val');
      expect(await memory.retrieve('key'), equals('val'));
    });
  });
}
