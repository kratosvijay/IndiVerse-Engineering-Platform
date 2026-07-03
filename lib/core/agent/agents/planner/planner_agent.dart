import '../../contracts/agent.dart';
import '../../contracts/decision_record.dart';
import '../../context/agent_context.dart';

class PlannerAgent implements Agent {
  @override
  String get id => "planner";
  @override
  String get name => "Planner Agent";
  @override
  String get version => "1.0.0";
  @override
  String get description => "Stateless micro-agent executing planner concerns.";
  @override
  List<String> get capabilities => const ["planner"];

  @override
  Future<DecisionRecord> execute(AgentContext context) async {
    return const DecisionRecord(
      id: "dr-planner",
      version: "1.0",
      reasoning: "Task completed successfully inside planner scope.",
      knowledgeSources: [],
      workspaceSources: [],
      confidence: 0.95,
      estimatedCost: 0.0,
      estimatedTokens: 0,
      riskLevel: "low",
      recommendedAction: "continue",
    );
  }
}
