import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/git/git_models.dart';
import 'package:indiverse_developer_platform/core/agent/git/git_policy_engine.dart';
import 'package:indiverse_developer_platform/core/agent/git/commit_message_generator.dart';
import 'package:indiverse_developer_platform/core/agent/git/pull_request_generator.dart';
import 'package:indiverse_developer_platform/core/agent/git/merge_conflict_resolver.dart';
import 'package:indiverse_developer_platform/core/agent/git/git_history_manager.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/git_tools.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';

class TestToolRegistry extends ToolRegistry {}

class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 22.5 - Git Intelligence & Autonomous Pull Requests Tests', () {
    setUp(() {
      GitHistoryRegistry.clear();
    });

    test('GitBranch metadata initializes with correct branch purposes', () {
      final branch = GitBranch(
        name: 'feature/agent-1',
        baseBranch: 'main',
        projectId: 'proj-1',
        executionId: 'exec-1',
        createdAt: DateTime.now(),
        purpose: GitBranchPurpose.feature,
      );

      expect(branch.name, equals('feature/agent-1'));
      expect(branch.purpose, equals(GitBranchPurpose.feature));
    });

    test('GitPolicyEngine checks branch policies and review score gates', () {
      const engine = GitPolicyEngine();

      final mainBranch = GitBranch(
        name: 'main',
        baseBranch: 'main',
        projectId: 'proj-1',
        executionId: 'exec-1',
        createdAt: DateTime.now(),
        purpose: GitBranchPurpose.feature,
      );
      final featureBranch = GitBranch(
        name: 'feature/agent-1',
        baseBranch: 'main',
        projectId: 'proj-1',
        executionId: 'exec-1',
        createdAt: DateTime.now(),
        purpose: GitBranchPurpose.feature,
      );

      final gateMain = engine.checkCommitGates(mainBranch, 9.5);
      expect(gateMain.passesGates, isFalse);
      expect(gateMain.errors.first,
          contains('direct commits to main branch are forbidden'));

      final gateLowScore = engine.checkCommitGates(featureBranch, 5.0);
      expect(gateLowScore.passesGates, isFalse);
      expect(gateLowScore.errors.first, contains('below threshold 7.0'));

      final gatePass = engine.checkCommitGates(featureBranch, 9.0);
      expect(gatePass.passesGates, isTrue);
    });

    test(
        'CommitMessageGenerator outputs standard Conventional Commits with meta trailers',
        () {
      const generator = CommitMessageGenerator();
      final msg = generator.generateMessage(
        type: 'feat',
        scope: 'editor',
        description: 'implement PR panel UI',
        projectId: 'proj-123',
        executionId: 'exec-456',
      );

      expect(msg, startsWith('feat(editor): implement PR panel UI'));
      expect(msg, contains('Project-ID: proj-123'));
      expect(msg, contains('Execution-ID: exec-456'));
    });

    test(
        'PullRequestGenerator compiles structured PullRequestDraft to markdown',
        () {
      const generator = PullRequestGenerator();
      const draft = PullRequestDraft(
        title: 'feat(auth): OAuth integration',
        summary: 'Adds login screen views.',
        changes: ['Create auth_panel.dart'],
        risks: ['None'],
        verificationResults: ['All Passed'],
        adrReferences: ['ADR 1'],
        relatedTasks: ['task-1'],
      );

      final markdown = generator.generateDescription(draft);
      expect(markdown, contains('# PR Draft: feat(auth): OAuth integration'));
      expect(markdown, contains('- Create auth_panel.dart'));
    });

    test('MergeConflictResolver auto-resolves simple conflicts', () {
      const resolver = MergeConflictResolver();

      const conflictUnresolvable = MergeConflict(
        filePath: 'lib/main.dart',
        conflictContent:
            '<<<<<<< HEAD\nvoid test() {}\n=======\nvoid main() {}\n>>>>>>> feature',
        autoResolvable: false,
      );
      final resUnresolved = resolver.resolveConflict(conflictUnresolvable);
      expect(resUnresolved.autoResolvable, isFalse);

      const conflictResolvable = MergeConflict(
        filePath: 'lib/main.dart',
        conflictContent:
            '<<<<<<< HEAD\n// original\n=======\n// Auto-resolvable\nvoid test() {}\n>>>>>>> feature',
        autoResolvable: false,
      );
      final resResolved = resolver.resolveConflict(conflictResolvable);
      expect(resResolved.autoResolvable, isTrue);
      expect(resResolved.conflictContent, contains('void test() {}'));
      expect(resResolved.conflictContent, isNot(contains('<<<<<<< HEAD')));
    });

    test('Git Tools execute via ToolExecutionService successfully', () async {
      final registry = TestToolRegistry();
      registry.register(GitCreateBranchTool());
      registry.register(GitCommitTool());
      registry.register(GitPlatformDiffTool());
      registry.register(GitLogTool());
      registry.register(GitPlatformStatusTool());

      final service = ToolExecutionService(
        registry: registry,
        permissionStore: TestPermissionStore(),
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'conv-git',
        requestId: 'req-git',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestCreate = const ToolCallRequest(
        toolCallId: 'call-create',
        toolName: 'git.create_branch',
        arguments: {'branchName': 'feature/editor-ui'},
      );

      final resCreate = await service.execute(requestCreate, context);
      expect(resCreate.success, isTrue);

      final requestCommit = const ToolCallRequest(
        toolCallId: 'call-commit',
        toolName: 'git.commit',
        arguments: {'message': 'feat(editor): implement Git UI'},
      );

      final resCommit = await service.execute(requestCommit, context);
      expect(resCommit.success, isTrue);
    });
  });
}
