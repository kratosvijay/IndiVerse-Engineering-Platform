enum CallType {
  normal,
  constructor,
  staticCall,
  extensionCall,
  superCall,
  thisCall
}

class CallEdge {
  final String callerId;
  final String calleeId;
  final CallType type;

  const CallEdge({
    required this.callerId,
    required this.calleeId,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallEdge &&
          runtimeType == other.runtimeType &&
          callerId == other.callerId &&
          calleeId == other.calleeId &&
          type == other.type;

  @override
  int get hashCode => callerId.hashCode ^ calleeId.hashCode ^ type.hashCode;
}

class CallGraph {
  final Map<String, List<CallEdge>> _callsFrom = {};
  final Map<String, List<CallEdge>> _callsTo = {};

  void addCall(String callerId, String calleeId, CallType type) {
    final edge = CallEdge(callerId: callerId, calleeId: calleeId, type: type);

    _callsFrom.putIfAbsent(callerId, () => []);
    if (!_callsFrom[callerId]!.contains(edge)) {
      _callsFrom[callerId]!.add(edge);
    }

    _callsTo.putIfAbsent(calleeId, () => []);
    if (!_callsTo[calleeId]!.contains(edge)) {
      _callsTo[calleeId]!.add(edge);
    }
  }

  void removeCallsForFile(String filePath) {
    // A file path matches in symbol IDs starting with `workspace://relative/path.dart#`
    final prefix = "workspace://$filePath#";

    // Remove outgoing calls
    _callsFrom.removeWhere((key, _) => key.startsWith(prefix));
    for (final key in _callsFrom.keys) {
      _callsFrom[key]!.removeWhere((edge) => edge.calleeId.startsWith(prefix));
    }

    // Remove incoming calls
    _callsTo.removeWhere((key, _) => key.startsWith(prefix));
    for (final key in _callsTo.keys) {
      _callsTo[key]!.removeWhere((edge) => edge.callerId.startsWith(prefix));
    }
  }

  void clear() {
    _callsFrom.clear();
    _callsTo.clear();
  }

  List<CallEdge> getOutgoingCalls(String callerId) {
    return List.unmodifiable(_callsFrom[callerId] ?? []);
  }

  List<CallEdge> getIncomingCalls(String calleeId) {
    return List.unmodifiable(_callsTo[calleeId] ?? []);
  }

  List<String> getCallers(String methodId) {
    return (_callsTo[methodId] ?? []).map((edge) => edge.callerId).toList();
  }

  List<String> getCallees(String methodId) {
    return (_callsFrom[methodId] ?? []).map((edge) => edge.calleeId).toList();
  }
}
