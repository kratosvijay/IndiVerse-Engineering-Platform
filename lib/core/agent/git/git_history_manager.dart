import 'git_models.dart';

class GitHistoryManager {
  final List<GitCommit> commitsHistory = [];
  final List<GitBranch> branchesHistory = [];

  void logBranchCheckout(GitBranch branch) {
    branchesHistory.add(branch);
  }

  void logCommit(GitCommit commit) {
    commitsHistory.add(commit);
  }

  // Performs rollback to target commit hash
  GitCommit? rollbackToCommit(String hash) {
    final idx = commitsHistory.indexWhere((c) => c.hash == hash);
    if (idx == -1) return null;

    final target = commitsHistory[idx];
    commitsHistory.removeRange(idx + 1, commitsHistory.length);
    return target;
  }
}

class GitHistoryRegistry {
  static GitHistoryManager? _active;
  static GitHistoryManager? get active => _active;
  static set active(GitHistoryManager? mgr) => _active = mgr;

  static final Map<String, GitHistoryManager> _registry = {};
  static void register(String workspaceId, GitHistoryManager manager) {
    _registry[workspaceId] = manager;
    _active ??= manager;
  }

  static GitHistoryManager? get(String workspaceId) => _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
