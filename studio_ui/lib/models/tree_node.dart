class TreeNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<TreeNode> children;
  bool isExpanded;
  String gitStatus;
  int size;
  String modified;

  TreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    List<TreeNode>? children,
    this.isExpanded = false,
    this.gitStatus = 'clean',
    this.size = 0,
    this.modified = '',
  }) : children = children ?? [];
}
