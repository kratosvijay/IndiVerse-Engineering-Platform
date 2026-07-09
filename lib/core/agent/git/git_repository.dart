import 'git_models.dart';

abstract interface class GitRepository {
  Future<void> checkout(String branch);
  Future<void> commit(GitCommit commit);
  Future<void> merge(String sourceBranch);
  Future<GitExecutionContext> getContext();
}

class LocalGitRepository implements GitRepository {
  String activeBranch = 'main';
  final List<GitCommit> commits = [];

  @override
  Future<void> checkout(String branch) async {
    activeBranch = branch;
  }

  @override
  Future<void> commit(GitCommit commit) async {
    commits.add(commit);
  }

  @override
  Future<void> merge(String sourceBranch) async {
    activeBranch = 'main';
  }

  @override
  Future<GitExecutionContext> getContext() async {
    return GitExecutionContext(
      activeBranch: activeBranch,
      remoteUrl: 'https://github.com/kratosvijay/IndiVerse-Engineering-Platform.git',
      localConfigs: const {
        'user.name': 'IndiVerse AI',
        'user.email': 'ai@indiverse.io',
      },
    );
  }
}
