import '../context/agent_context.dart';

class AgentSession {
  final AgentContext context;
  Duration duration = Duration.zero;

  AgentSession(this.context);
}
