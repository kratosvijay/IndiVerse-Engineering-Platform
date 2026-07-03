import 'dart:async';
import '../models/ai_request.dart';
import '../models/execution_result.dart';
import '../contracts/runtime_core.dart';

enum TaskPriority { low, normal, high }

class ScheduledTask {
  final String id;
  final AIRequest request;
  final TaskPriority priority;
  final Completer<ExecutionResult> completer = Completer<ExecutionResult>();

  ScheduledTask({
    required this.id,
    required this.request,
    required this.priority,
  });
}

class AIScheduler {
  final RuntimeCore _runtime;
  final List<ScheduledTask> _queue = [];
  bool _isProcessing = false;

  AIScheduler(this._runtime);

  List<ScheduledTask> get queue => List.unmodifiable(_queue);

  Future<ExecutionResult> schedule(AIRequest request,
      {TaskPriority priority = TaskPriority.normal}) {
    final task = ScheduledTask(
      id: "task-${DateTime.now().millisecondsSinceEpoch}-${request.modelName}",
      request: request,
      priority: priority,
    );
    _queue.add(task);
    // Sort: high priority first
    _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    _processQueue();
    return task.completer.future;
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    final task = _queue.removeAt(0);
    try {
      final res = await _runtime.execute(task.request);
      task.completer.complete(res);
    } catch (e) {
      task.completer.completeError(e);
    } finally {
      _isProcessing = false;
      // Yield to event loop to prevent deep recursion stacks
      Timer.run(_processQueue);
    }
  }
}
