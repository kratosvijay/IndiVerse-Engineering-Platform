import 'agent_role.dart';
import 'agent_role_extensions.dart';

class AgentRegistry {
  final Map<String, CollabAgent> _registry = {};

  AgentRegistry() {
    // Register defaults
    register(PlannerAgent());
    register(CodingAgent());
    register(ReviewAgent());
    register(TestingAgent());
    register(DocumentationAgent());
    register(RefactoringAgent());
  }

  void register(CollabAgent agent) {
    _registry[agent.descriptor.id] = agent;
  }

  void unregister(String id) {
    _registry.remove(id);
  }

  CollabAgent? getAgent(String id) => _registry[id];

  List<CollabAgent> getAgentsByRole(AgentRole role) {
    return _registry.values.where((a) => a.descriptor.role == role).toList();
  }

  List<CollabAgent> getAgentsByCapability(AgentCapability cap) {
    return _registry.values
        .where((a) => a.descriptor.capabilities.contains(cap))
        .toList();
  }

  List<CollabAgent> listAgents() => List.unmodifiable(_registry.values);
}
