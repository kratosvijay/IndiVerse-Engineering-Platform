class SymbolModel {
  final String id;
  final String name;
  final String kind;
  final String filePath;
  final Map<String, dynamic> metadata;

  const SymbolModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.filePath,
    this.metadata = const {},
  });
}
