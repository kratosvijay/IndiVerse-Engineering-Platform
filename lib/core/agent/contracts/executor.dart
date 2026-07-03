import '../context/agent_context.dart';
import 'decision_record.dart';
import 'agent.dart';

abstract class AgentExecutor {
  Future<DecisionRecord> run(Agent agent, AgentContext context);
}
