import '../../contracts/agent.dart';
import '../../contracts/decision_record.dart';
import '../../context/agent_context.dart';

class TesterAgent implements Agent {
  @override
  String get id => "tester";
  @override
  String get name => "Tester Agent";
  @override
  String get version => "1.0.0";
  @override
  String get description => "Stateless micro-agent executing tester concerns.";
  @override
  List<String> get capabilities => const ["tester"];

  @override
  Future<DecisionRecord> execute(AgentContext context) async {
    return const DecisionRecord(
      id: "dr-tester",
      version: "1.0",
      reasoning: "Task completed successfully inside tester scope.",
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
