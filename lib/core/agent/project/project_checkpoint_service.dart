import 'project_models.dart';

class ProjectCheckpointService {
  final Map<String, List<ExecutionCheckpoint>> _projectCheckpoints = {};

  // Persists a snapshot checkpoint for verification/rollback
  Future<void> saveCheckpoint(ExecutionCheckpoint checkpoint) async {
    final list = _projectCheckpoints.putIfAbsent(checkpoint.projectId, () => []);
    list.add(checkpoint);
  }

  // Retrieves history records
  Future<List<ExecutionCheckpoint>> getCheckpoints(String projectId) async {
    return _projectCheckpoints[projectId] ?? const [];
  }

  // Performs rollback to target checkpointId
  Future<ExecutionCheckpoint?> rollback(String projectId, String checkpointId) async {
    final list = _projectCheckpoints[projectId];
    if (list == null) return null;

    final index = list.indexWhere((c) => c.checkpointId == checkpointId);
    if (index == -1) return null;

    // Truncates subsequent checkpoints
    final target = list[index];
    list.removeRange(index + 1, list.length);
    return target;
  }
}
