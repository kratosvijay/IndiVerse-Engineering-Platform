class DocumentId {
  final String value;
  const DocumentId(this.value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DocumentId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class SymbolId {
  final String value;
  const SymbolId(this.value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SymbolId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class WorkspaceId {
  final String value;
  const WorkspaceId(this.value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkspaceId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class NodeId {
  final String value;
  const NodeId(this.value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NodeId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class AgentId {
  final String value;
  const AgentId(this.value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AgentId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
