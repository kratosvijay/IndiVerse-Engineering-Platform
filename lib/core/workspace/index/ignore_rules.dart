class IgnoreRules {
  final List<String> ignorePatterns;

  IgnoreRules(
      {this.ignorePatterns = const [
        "build",
        ".git",
        ".dart_tool",
        "node_modules",
        "coverage",
        ".idea",
        ".vscode"
      ]});

  bool shouldIgnore(String path) {
    for (final pattern in ignorePatterns) {
      if (path.contains("/$pattern/") || path.endsWith("/$pattern")) {
        return true;
      }
    }
    return false;
  }
}
