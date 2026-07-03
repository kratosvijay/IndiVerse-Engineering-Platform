enum SelectionType {
  file,
  folder,
  symbol,
  searchResult,
  workflow,
  architectureNode,
}

class Selection {
  final SelectionType type;
  final String id;
  final Map<String, dynamic> metadata;

  const Selection({
    required this.type,
    required this.id,
    required this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Selection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;

  @override
  String toString() => 'Selection(type: $type, id: $id)';
}
