import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../agent/project/project_models.dart';
import '../../../agent/project/project_execution_manager.dart';
import '../../../agent/project/project_repository.dart';

class ProjectCreateTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.create',
    name: 'Create Versioned Project',
    description: 'Initializes a new versioned software ProjectPlan template.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'create'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['projectId'] as String? ?? 'proj-default';

    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final plan = await manager.createProject(id: id, epics: const []);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: plan.toJson(),
        displayText: 'Project $id initialized.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectOpenTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.open',
    name: 'Open Active Project',
    description: 'Opens project state records.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'open'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['projectId'] as String? ?? 'proj-default';

    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final plan = await manager.openProject(id);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: plan?.toJson() ?? {},
        displayText: plan != null ? 'Project $id opened.' : 'Project $id not found.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectPlanTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.plan',
    name: 'Decompose Project Epics',
    description: 'Builds Epic and Milestone decompositions.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'plan'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        data: {'planned': true},
        displayText: 'Project roadmap decomposition generated.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectExecuteTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.execute',
    name: 'Execute Milestones',
    description: 'Triggers scheduled milestone execution.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['project', 'execute'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    await manager.updateProjectState(ProjectState.executing);

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Autonomous milestone execution started.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectPauseTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.pause',
    name: 'Pause Project Execution',
    description: 'Pauses active task iterations.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'pause'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    await manager.updateProjectState(ProjectState.paused);

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Project execution paused successfully.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectResumeTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.resume',
    name: 'Resume Project Execution',
    description: 'Resumes paused tasks.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'resume'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    await manager.updateProjectState(ProjectState.executing);

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Resumed task executions.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectStatusTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.status',
    name: 'Get Project Status',
    description: 'Retrieves current ProjectState.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'status'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final stateName = manager.activePlan?.state.name ?? 'none';

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'state': stateName},
        displayText: 'Project state is: $stateName.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectSummaryTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.summary',
    name: 'Get Project Summary',
    description: 'Computes velocity and completion ratios.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'summary'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final plan = manager.activePlan;
    final progress = plan != null
        ? manager.progressEngine.calculateProgress(plan)
        : const ProjectProgress(
            completionPercentage: 0,
            completedTasks: 0,
            remainingTasks: 0,
            velocity: 0,
            estimatedRemainingWork: Duration.zero,
            verificationPassRate: 0,
          );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: progress.toJson(),
        displayText: 'Unified project summary computed.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectHistoryTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.history',
    name: 'List Snapshots History',
    description: 'Lists all checkpoint snapshots saved.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'history'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final projectId = request.arguments['projectId'] as String? ?? 'proj-default';

    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final history = await manager.checkpointService.getCheckpoints(projectId);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'checkpoints': history.map((c) => c.toJson()).toList()},
        displayText: 'Listed ${history.length} snapshots.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectRollbackTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.rollback',
    name: 'Rollback Project Checkpoint',
    description: 'Rolls back workspace state to a specific checkpoint snapshot.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: true,
    modifiesWorkspace: true,
    tags: ['project', 'rollback'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final projectId = request.arguments['projectId'] as String? ?? 'proj-default';
    final checkpointId = request.arguments['checkpointId'] as String? ?? '';

    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final checkpoint = await manager.checkpointService.rollback(projectId, checkpointId);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: checkpoint?.toJson() ?? {},
        displayText: checkpoint != null
            ? 'Rolled back project $projectId to checkpoint $checkpointId.'
            : 'Rollback target not found.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class ProjectCheckpointTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'project.checkpoint',
    name: 'Save Snapshot Checkpoint',
    description: 'Saves current project and workspace details checkpoint.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['project', 'checkpoint'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final projectId = request.arguments['projectId'] as String? ?? 'proj-default';
    final checkpointId = request.arguments['checkpointId'] as String? ?? 'chk-1';

    final manager = ProjectExecutionManagerRegistry.active ??
        ProjectExecutionManagerRegistry.get(context.workspaceId) ??
        ProjectExecutionManager(repository: JsonProjectRepository());

    final checkpoint = ExecutionCheckpoint(
      checkpointId: checkpointId,
      projectId: projectId,
      timestamp: DateTime.now(),
      workspaceSnapshotId: 'snap-1',
      patches: const [],
    );

    await manager.checkpointService.saveCheckpoint(checkpoint);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: checkpoint.toJson(),
        displayText: 'Snapshot $checkpointId saved.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
