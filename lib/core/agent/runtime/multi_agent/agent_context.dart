import '../../../prompt/prompt_pipeline.dart';
import '../../../workspace/graph/workspace_snapshot.dart';
import '../agent_runtime.dart';
import 'agent_memory.dart';
import 'agent_message_bus.dart';

class AgentContext {
  final WorkspaceSnapshot snapshot;
  final SharedMemory memory;
  final AgentMessageBus bus;
  final CancellationToken cancellationToken;
  final AgentRuntime runtime;

  const AgentContext({
    required this.snapshot,
    required this.memory,
    required this.bus,
    required this.cancellationToken,
    required this.runtime,
  });
}
