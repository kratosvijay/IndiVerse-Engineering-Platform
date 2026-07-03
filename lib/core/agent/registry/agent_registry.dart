import '../contracts/agent.dart';

class AgentRegistry {
  final Map<String, Agent> _agents = {};

  void register(Agent agent) {
    _agents[agent.id] = agent;
  }

  List<Agent> list() => _agents.values.toList();
}
