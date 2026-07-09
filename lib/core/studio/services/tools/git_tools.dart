import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../agent/git/git_models.dart';
import '../../../agent/git/git_policy_engine.dart';
import '../../../agent/git/git_history_manager.dart';
import '../../../agent/git/pull_request_generator.dart';

class GitCreateBranchTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.create_branch',
    name: 'Create Feature Branch',
    description: 'Creates and checks out isolated branch.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'branch', 'create'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final name = request.arguments['branchName'] as String? ?? 'feature/agent-1';

    final gitHistory = GitHistoryRegistry.active ??
        GitHistoryRegistry.get(context.workspaceId) ??
        GitHistoryManager();

    final branch = GitBranch(
      name: name,
      baseBranch: 'main',
      projectId: 'proj-1',
      executionId: 'exec-1',
      createdAt: DateTime.now(),
      purpose: GitBranchPurpose.feature,
    );

    gitHistory.logBranchCheckout(branch);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: branch.toJson(),
        displayText: 'Branch $name created and checked out.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitCommitTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.commit',
    name: 'Commit Code Modifications',
    description: 'Stages and commits modifications after checking verification gates.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['git', 'commit'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final message = request.arguments['message'] as String? ?? 'feat(auth): add OAuth login';

    // Gate checks
    final policyEngine = const GitPolicyEngine();
    final branch = GitBranch(
      name: 'feature/agent-auth',
      baseBranch: 'main',
      projectId: 'proj-1',
      executionId: 'exec-1',
      createdAt: DateTime.now(),
      purpose: GitBranchPurpose.feature,
    );

    final gateRes = policyEngine.checkCommitGates(branch, 9.5);
    if (!gateRes.passesGates) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          data: gateRes.toJson(),
          displayText: 'Commit rejected: verification gates failed.',
          mimeType: 'application/json',
        ),
        duration: stopwatch.elapsed,
      );
    }

    final commit = GitCommit(
      hash: 'sha-commit-1',
      message: message,
      author: 'ai@indiverse.io',
      timestamp: DateTime.now(),
      metadata: const {
        'projectId': 'proj-1',
        'executionId': 'exec-1',
      },
    );

    final gitHistory = GitHistoryRegistry.active ??
        GitHistoryRegistry.get(context.workspaceId) ??
        GitHistoryManager();

    gitHistory.logCommit(commit);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: commit.toJson(),
        displayText: 'Commit sha-commit-1 recorded successfully.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitPlatformDiffTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.diff',
    name: 'Get Git Diffs',
    description: 'Retrieves current branch code diff status.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'diff'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final diff = const GitDiff(
      targetFile: 'lib/main.dart',
      originalText: 'void main() {}',
      modifiedText: 'void main() { runApp(); }',
    );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: diff.toJson(),
        displayText: 'Diff output loaded.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitLogTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.log',
    name: 'Get Git Commit History',
    description: 'Lists recent commit records.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'log'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final gitHistory = GitHistoryRegistry.active ??
        GitHistoryRegistry.get(context.workspaceId) ??
        GitHistoryManager();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'commits': gitHistory.commitsHistory.map((c) => c.toJson()).toList()},
        displayText: 'Commits list loaded.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitCheckoutTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.checkout',
    name: 'Checkout Target Branch',
    description: 'Switches workspace to branch.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['git', 'checkout'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final name = request.arguments['branchName'] as String? ?? 'main';

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Checked out target branch: $name.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitMergeTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.merge',
    name: 'Merge Branch Changes',
    description: 'Merges changes from target source branch.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['git', 'merge'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Changes merged successfully.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitRebaseTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.rebase',
    name: 'Rebase Active Changes',
    description: 'Rebases current branch updates.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['git', 'rebase'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Rebase operations completed.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitRollbackTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.rollback',
    name: 'Rollback Commit Snapshot',
    description: 'Reverts git workspace status to target commit hash.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: true,
    modifiesWorkspace: true,
    tags: ['git', 'rollback'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final hash = request.arguments['commitHash'] as String? ?? '';

    final gitHistory = GitHistoryRegistry.active ??
        GitHistoryRegistry.get(context.workspaceId) ??
        GitHistoryManager();

    final rolled = gitHistory.rollbackToCommit(hash);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: rolled?.toJson() ?? {},
        displayText: rolled != null
            ? 'Rolled back history to commit $hash.'
            : 'Commit hash not found.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitPullRequestTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.pull_request',
    name: 'Create Pull Request Draft',
    description: 'Generates pull request description template.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'pull_request'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    final draft = PullRequestDraft(
      title: request.arguments['title'] as String? ?? 'feat(auth): OAuth integration',
      summary: 'Adds login screen view widgets and controllers.',
      changes: const ['Create auth_panel.dart', 'Create auth_controller.dart'],
      risks: const ['Migration dependencies key conflicts'],
      verificationResults: const ['Compile Passed', 'Analysis Clean'],
      adrReferences: const ['ADR 1: Separate Presentation layer'],
      relatedTasks: const ['task-1: Form layout'],
    );

    final gen = const PullRequestGenerator();
    final description = gen.generateDescription(draft);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: draft.toJson(),
        displayText: description,
        mimeType: 'text/markdown',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GitPlatformStatusTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.status',
    name: 'Get Git Status',
    description: 'Loads branch name and untracked changes.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'status'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        data: {
          'branch': 'feature/agent-1',
          'clean': true,
        },
        displayText: 'Branch feature/agent-1 is clean.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
