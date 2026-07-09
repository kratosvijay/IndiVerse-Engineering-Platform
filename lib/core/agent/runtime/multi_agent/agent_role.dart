enum AgentRole { planner, coder, reviewer, tester, documenter, refactorer }

enum AgentCapability {
  planning,
  coding,
  testing,
  review,
  documentation,
  refactoring,
  toolExecution,
  workspaceAnalysis
}

class AgentDescriptor {
  final String id;
  final String name;
  final AgentRole role;
  final List<AgentCapability> capabilities;

  const AgentDescriptor({
    required this.id,
    required this.name,
    required this.role,
    required this.capabilities,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'capabilities': capabilities.map((c) => c.name).toList(),
      };
}
