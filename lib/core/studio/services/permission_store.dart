import '../../models/tool_call_models.dart';

class ToolPermissionStore {
  final Map<String, PermissionDecision> _store = {};

  void saveDecision(String toolId, PermissionDecision decision) {
    if (decision == PermissionDecision.allowAlways || decision == PermissionDecision.denyAlways) {
      _store[toolId] = decision;
    }
  }

  PermissionDecision? getDecision(String toolId) {
    return _store[toolId];
  }

  void clearDecision(String toolId) {
    _store.remove(toolId);
  }

  void clearAll() {
    _store.clear();
  }
}
