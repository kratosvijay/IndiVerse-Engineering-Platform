import 'dart:async';
import '../../../../platform_sdk/platform_sdk.dart';
import '../../events/event_bus.dart';
import '../../workspace/events/workspace_event.dart';

class AgentService {
  final PlatformSDK sdk;
  final EventBus eventBus;

  final List<Map<String, dynamic>> _history = [];
  String _currentStatus = "idle";
  String? _activeWorkflowId;

  AgentService(this.sdk, this.eventBus);

  List<Map<String, dynamic>> getAvailableWorkflows() {
    return const [
      {
        "name": "Planner",
        "description": "Constructs multi-step execution plans",
        "requiredCapabilities": ["planning"],
        "estimatedDuration": "3s",
        "requiresApproval": true,
      },
      {
        "name": "Developer",
        "description": "Applies targeted code mutations",
        "requiredCapabilities": ["coding"],
        "estimatedDuration": "5s",
        "requiresApproval": false,
      },
      {
        "name": "Reviewer",
        "description": "Analyzes code quality and standards compliance",
        "requiredCapabilities": ["reviewing"],
        "estimatedDuration": "2s",
        "requiresApproval": true,
      }
    ];
  }

  Future<Map<String, dynamic>> runWorkflow(String name) async {
    _currentStatus = "running";
    _activeWorkflowId = "wf-${DateTime.now().millisecondsSinceEpoch}";

    final record = {
      "workflowId": _activeWorkflowId,
      "name": name,
      "status": "running",
      "timestamp": DateTime.now().toIso8601String(),
    };
    _history.add(record);

    // Stream real event mapping down the EventBus pipeline
    eventBus.publish(WorkspaceRefreshing(
      timestamp: DateTime.now(),
      eventId: "refresh-${DateTime.now().millisecondsSinceEpoch}",
      rootPath: "",
    ));

    return record;
  }

  Future<Map<String, dynamic>> cancelWorkflow(String workflowId) async {
    if (_activeWorkflowId == workflowId) {
      _currentStatus = "cancelled";
      for (final item in _history) {
        if (item["workflowId"] == workflowId) {
          item["status"] = "cancelled";
        }
      }
      return {"workflowId": workflowId, "status": "cancelled"};
    }
    throw Exception("Workflow ID not found or not active: $workflowId");
  }

  Map<String, dynamic> getStatus() {
    return {
      "status": _currentStatus,
      "activeWorkflowId": _activeWorkflowId,
    };
  }

  List<Map<String, dynamic>> getHistory() {
    return _history;
  }
}
