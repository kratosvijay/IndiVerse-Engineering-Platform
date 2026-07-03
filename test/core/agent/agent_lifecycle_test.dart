import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/contracts/agent.dart';
import 'package:indiverse_developer_platform/core/agent/agents/planner/planner_agent.dart';

void main() {
  group('Agent Lifecycle Tests', () {
    test('Verify planner agent info and execution', () async {
      final Agent agent = PlannerAgent();
      expect(agent.id, equals('planner'));
      expect(agent.capabilities, contains('planner'));
    });
  });
}
