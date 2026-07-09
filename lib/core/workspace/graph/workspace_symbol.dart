enum SymbolKind {
  classSymbol,
  method,
  field,
  enumSymbol,
  mixin,
  typedefSymbol,
  extensionSymbol
}

enum SymbolVisibility { public, private, protected }

class WorkspaceSymbol {
  final String id; // Format: workspace://relative/path.dart#Parent.child
  final String name;
  final SymbolKind kind;
  final SymbolVisibility visibility;
  final String? libraryName;
  final String filePath;
  final int startLine;
  final int endLine;
  final int column;
  final String? documentation;
  final List<String> annotations;
  final List<String> parentIds;
  final List<String> childrenIds;

  const WorkspaceSymbol({
    required this.id,
    required this.name,
    required this.kind,
    required this.visibility,
    this.libraryName,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.column,
    this.documentation,
    required this.annotations,
    required this.parentIds,
    required this.childrenIds,
  });

  WorkspaceSymbol copyWith({
    String? id,
    String? name,
    SymbolKind? kind,
    SymbolVisibility? visibility,
    String? libraryName,
    String? filePath,
    int? startLine,
    int? endLine,
    int? column,
    String? documentation,
    List<String>? annotations,
    List<String>? parentIds,
    List<String>? childrenIds,
  }) {
    return WorkspaceSymbol(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      visibility: visibility ?? this.visibility,
      libraryName: libraryName ?? this.libraryName,
      filePath: filePath ?? this.filePath,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      column: column ?? this.column,
      documentation: documentation ?? this.documentation,
      annotations: annotations ?? this.annotations,
      parentIds: parentIds ?? this.parentIds,
      childrenIds: childrenIds ?? this.childrenIds,
    );
  }
}
