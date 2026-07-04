class FoldingRegion {
  final int startLine;
  final int endLine;
  final bool collapsed;
  final String signature;
  final List<FoldingRegion> children;

  const FoldingRegion({
    required this.startLine,
    required this.endLine,
    required this.signature,
    this.collapsed = false,
    this.children = const [],
  });

  FoldingRegion copyWith({
    int? startLine,
    int? endLine,
    bool? collapsed,
    String? signature,
    List<FoldingRegion>? children,
  }) {
    return FoldingRegion(
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      collapsed: collapsed ?? this.collapsed,
      signature: signature ?? this.signature,
      children: children ?? this.children,
    );
  }

  List<FoldingRegion> toFlatList() {
    final List<FoldingRegion> flat = [this];
    for (final child in children) {
      flat.addAll(child.toFlatList());
    }
    return flat;
  }
}
