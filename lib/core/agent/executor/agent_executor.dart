import '../contracts/executor.dart';
import '../contracts/agent.dart';
import '../contracts/decision_record.dart';
import '../context/agent_context.dart';
import 'agent_session.dart';

class AgentExecutorImpl implements AgentExecutor {
  @override
  Future<DecisionRecord> run(Agent agent, AgentContext context) async {
    final session = AgentSession(context);
    final start = DateTime.now();
    final record = await agent.execute(context);
    session.duration = DateTime.now().difference(start);
    return record;
  }
}
