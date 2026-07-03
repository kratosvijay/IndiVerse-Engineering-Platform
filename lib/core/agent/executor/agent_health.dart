class AgentHealth {
  final Duration lastExecutionTime;
  final Duration averageLatency;
  final double successRate;

  const AgentHealth({
    required this.lastExecutionTime,
    required this.averageLatency,
    required this.successRate,
  });
}
