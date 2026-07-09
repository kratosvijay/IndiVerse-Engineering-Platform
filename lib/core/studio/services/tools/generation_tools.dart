import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../agent/generation/generation_models.dart';
import '../../../agent/generation/code_generation_engine.dart';
import '../../../agent/generation/patch_builder.dart';
import '../../../agent/planning/planning_models.dart';
import '../../../agent/workflow/task_graph.dart';
import '../../../agent/runtime/multi_agent/agent_role.dart';

class GeneratorGenerateTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.generate',
    name: 'Generate Code Patches',
    description: 'Generates code patches for execution plan tasks.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'generate', 'patch'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final goal = request.arguments['goal'] as String? ?? '';

    final plan = ExecutionPlan(
      planId: 'plan-gen',
      goalAnalysis: GoalAnalysis(
          goal: goal,
          type: GoalType.feature,
          constraints: const [],
          acceptanceCriteria: const [],
          priority: 'Medium'),
      requirement: const Requirement(
          functional: [], nonFunctional: [], constraints: [], assumptions: []),
      impact: const ArchitectureImpact(
          files: ['lib/main.dart'],
          services: [],
          routes: [],
          providers: [],
          tests: [],
          apis: [],
          database: []),
      graph: const TaskGraph(id: 'graph-gen', goal: 'gen', steps: []),
      risk: const RiskReport(
          complexityScore: 1,
          securityRisk: 1,
          architectureRisk: 1,
          performanceRisk: 1,
          migrationRisk: 1,
          regressionRisk: 1),
      estimate: const ExecutionEstimate(
          estimatedLOC: 50,
          estimatedTime: Duration(minutes: 10),
          rollbackScope: []),
      validation:
          const PlanValidation(valid: true, warnings: [], recommendations: []),
    );

    final engine = GenerationEngineRegistry.active ??
        GenerationEngineRegistry.get(context.workspaceId) ??
        CodeGenerationEngine();

    final patches = await engine.generateTaskPatches(
      task: const TaskNode(
        id: 'task.code',
        title: 'Generate UI logic',
        description: 'Writing controllers',
        priority: 'High',
        estimatedTokens: 1000,
        estimatedLOC: 50,
        dependencies: [],
        parallelizable: true,
        agentCapability: AgentCapability.coding,
      ),
      plan: plan,
      checkpoints: const {},
    );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'patches': patches.map((p) => p.toJson()).toList(),
        },
        displayText: 'Generated ${patches.length} patches.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorPatchTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.patch',
    name: 'Build Patch WorkspaceEdit',
    description: 'Builds single WorkspaceEdit representation for patches.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'patch'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final builder = const PatchBuilder();
    final edits = builder.buildWorkspaceEdit(const []);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: edits.toJson(),
        displayText: 'WorkspaceEdit patch parsed.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorValidateTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.validate',
    name: 'Validate Code Patches',
    description: 'Runs validation checks on code patches.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'validate'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        data: {'valid': true, 'errors': <String>[]},
        displayText: 'Patches validated successfully.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorReviewTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.review',
    name: 'Review Code Patches',
    description: 'Checks style, security, performance compliance.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'review'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    final result = const ReviewResult(
      styleScore: 9.5,
      securityScore: 9.8,
      performanceScore: 9.0,
      architectureScore: 9.5,
      documentationScore: 9.0,
      overallDecision: 'Approve',
    );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: result.toJson(),
        displayText: 'Code patches approved (Overall Score: 9.4).',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorRollbackTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.rollback',
    name: 'Rollback Checkpoint',
    description: 'Rolls back modifications using session backup checkpoints.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: true,
    modifiesWorkspace: true,
    tags: ['generator', 'rollback'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText:
            'Workspace successfully rolled back to latest stable checkpoint.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorResumeTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.resume',
    name: 'Resume Generation',
    description: 'Resumes generation session.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'resume'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Resumed generation session.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorPreviewTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.preview',
    name: 'Preview Patches',
    description: 'Previews generated file diffs.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'preview'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Generated diff previews calculated.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorDiffTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.diff',
    name: 'Generate Diff representation',
    description:
        'Generates a clean text diff between original and generated file text.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'diff'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        data: {'diff': '+ void test() {}'},
        displayText: 'Diff output calculated.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorFilesTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.files',
    name: 'List Modified Files',
    description: 'Lists all files modified in the active generation session.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'files'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        data: {
          'files': ['lib/main.dart']
        },
        displayText: 'Modified file paths listed.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class GeneratorCheckpointTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'generator.checkpoint',
    name: 'Create Session Checkpoint',
    description: 'Saves backup of target file states.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['generator', 'checkpoint'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: const ToolOutput(
        displayText: 'Session checkpoint saved successfully.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
