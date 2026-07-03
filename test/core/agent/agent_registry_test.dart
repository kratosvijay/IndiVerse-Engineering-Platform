import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/registry/agent_registry.dart';
import 'package:indiverse_developer_platform/core/agent/agents/planner/planner_agent.dart';

void main() {
  group('AgentRegistry Tests', () {
    test('Register and list active agents', () {
      final registry = AgentRegistry();
      final planner = PlannerAgent();
      registry.register(planner);

      expect(registry.list().length, equals(1));
      expect(registry.list().first.id, equals('planner'));
    });
  });
}
