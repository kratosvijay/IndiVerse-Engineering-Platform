class ExplorerController {
  final Set<String> expandedPaths = {'/'};
  String? selectedPath;
  String? focusedPath;
  final Set<String> loadingPaths = {};

  bool isExpanded(String path) => expandedPaths.contains(path);

  void toggleExpand(String path) {
    if (expandedPaths.contains(path)) {
      expandedPaths.remove(path);
    } else {
      expandedPaths.add(path);
    }
  }

  void select(String path) {
    selectedPath = path;
  }

  void focus(String path) {
    focusedPath = path;
  }
}
