import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/agents/developer/developer_agent.dart';

void main() {
  group('CapabilityMatching Tests', () {
    test('Agent exposes developer capabilities', () {
      final agent = DeveloperAgent();
      expect(agent.capabilities, contains('developer'));
    });
  });
}
