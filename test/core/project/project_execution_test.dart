import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/project/project_models.dart';
import 'package:indiverse_developer_platform/core/agent/project/project_repository.dart';
import 'package:indiverse_developer_platform/core/agent/project/milestone_scheduler.dart';
import 'package:indiverse_developer_platform/core/agent/project/project_checkpoint_service.dart';
import 'package:indiverse_developer_platform/core/agent/project/project_progress_engine.dart';
import 'package:indiverse_developer_platform/core/agent/project/project_execution_manager.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/project_tools.dart';
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
  group('Sprint 22.4 - Project Manager & Autonomous Task Orchestration Tests', () {
    late JsonProjectRepository repository;
    late ProjectExecutionManager manager;

    setUp(() {
      repository = JsonProjectRepository();
      manager = ProjectExecutionManager(repository: repository);
      ProjectExecutionManagerRegistry.clear();
      ProjectExecutionManagerRegistry.register('test-ws', manager);
    });

    test('ProjectExecutionManager creates, opens, and saves projects correctly', () async {
      final epic = const Epic(
        id: 'epic-1',
        title: 'Core UI',
        description: 'Building layouts',
        milestones: [
          Milestone(
            id: 'ms-1',
            title: 'Auth Panel',
            description: 'SignIn Screen UI',
            isCompleted: false,
            tasks: [
              ProjectTask(
                id: 'task-1',
                title: 'Form layout',
                description: 'Write buttons',
                priority: 'High',
                status: ProjectTaskStatus.todo,
                dependencies: [],
              )
            ],
          )
        ],
      );

      final plan = await manager.createProject(id: 'project-engine', epics: [epic]);
      expect(plan.id, equals('project-engine'));
      expect(plan.version, equals(1));
      expect(plan.epics, hasLength(1));

      final opened = await manager.openProject('project-engine');
      expect(opened, isNotNull);
      expect(opened!.epics, hasLength(1));
    });

    test('MilestoneScheduler schedules tasks using Dependency and Priority strategies', () {
      final taskA = const ProjectTask(
        id: 'task-a',
        title: 'Task A',
        description: 'A description',
        priority: 'Low',
        status: ProjectTaskStatus.todo,
        dependencies: ['task-b'],
      );
      final taskB = const ProjectTask(
        id: 'task-b',
        title: 'Task B',
        description: 'B description',
        priority: 'High',
        status: ProjectTaskStatus.todo,
        dependencies: [],
      );

      final milestone = Milestone(
        id: 'ms-sort',
        title: 'Sorting Milestone',
        description: 'Sort logic testing',
        isCompleted: false,
        tasks: [taskA, taskB],
      );

      const scheduler = MilestoneScheduler();
      final scheduled = scheduler.scheduleMilestone(milestone);

      // Task B should be scheduled first because Task A depends on Task B
      expect(scheduled.tasks.first.id, equals('task-b'));
      expect(scheduled.tasks.last.id, equals('task-a'));
    });

    test('ProjectCheckpointService handles rollback snapshot limits', () async {
      final service = ProjectCheckpointService();
      final chk1 = ExecutionCheckpoint(
        checkpointId: 'chk-1',
        projectId: 'proj-1',
        timestamp: DateTime.now(),
        workspaceSnapshotId: 'ws-snap-1',
        patches: const [],
      );
      final chk2 = ExecutionCheckpoint(
        checkpointId: 'chk-2',
        projectId: 'proj-1',
        timestamp: DateTime.now(),
        workspaceSnapshotId: 'ws-snap-2',
        patches: const [],
      );

      await service.saveCheckpoint(chk1);
      await service.saveCheckpoint(chk2);

      final list = await service.getCheckpoints('proj-1');
      expect(list, hasLength(2));

      final rolled = await service.rollback('proj-1', 'chk-1');
      expect(rolled, isNotNull);
      expect(rolled!.checkpointId, equals('chk-1'));

      final listAfter = await service.getCheckpoints('proj-1');
      expect(listAfter, hasLength(1));
    });

    test('ProjectProgressEngine calculates correct progress state metrics', () {
      final plan = ProjectPlan(
        id: 'proj-progress',
        version: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        state: ProjectState.planning,
        epics: [
          const Epic(
            id: 'epic-progress',
            title: 'Progress Epic',
            description: 'Calculating percentages',
            milestones: [
              Milestone(
                id: 'ms-progress',
                title: 'Progress Milestone',
                description: 'Progress description',
                isCompleted: false,
                tasks: [
                  ProjectTask(
                    id: 'task-done',
                    title: 'Task Done',
                    description: 'done description',
                    priority: 'Medium',
                    status: ProjectTaskStatus.completed,
                    dependencies: [],
                  ),
                  ProjectTask(
                    id: 'task-todo',
                    title: 'Task Todo',
                    description: 'todo description',
                    priority: 'Medium',
                    status: ProjectTaskStatus.todo,
                    dependencies: [],
                  ),
                ],
              )
            ],
          )
        ],
      );

      const engine = ProjectProgressEngine();
      final progress = engine.calculateProgress(plan);

      expect(progress.completedTasks, equals(1));
      expect(progress.remainingTasks, equals(1));
      expect(progress.completionPercentage, equals(0.5));
    });

    test('Project Tools execute via ToolExecutionService successfully', () async {
      final registry = TestToolRegistry();
      registry.register(ProjectCreateTool());
      registry.register(ProjectOpenTool());
      registry.register(ProjectStatusTool());
      registry.register(ProjectSummaryTool());

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
        conversationId: 'conv-project',
        requestId: 'req-project',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestCreate = const ToolCallRequest(
        toolCallId: 'call-create',
        toolName: 'project.create',
        arguments: {'projectId': 'proj-test'},
      );

      final resCreate = await service.execute(requestCreate, context);
      expect(resCreate.success, isTrue);

      final requestStatus = const ToolCallRequest(
        toolCallId: 'call-status',
        toolName: 'project.status',
        arguments: {},
      );

      final resStatus = await service.execute(requestStatus, context);
      expect(resStatus.success, isTrue);
    });
  });
}
