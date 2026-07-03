import '../context/agent_context.dart';
import 'decision_record.dart';

abstract class Agent {
  String get id;
  String get name;
  String get version;
  String get description;
  List<String> get capabilities;

  Future<DecisionRecord> execute(AgentContext context);
}
