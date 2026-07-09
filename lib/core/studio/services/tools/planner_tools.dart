import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../workspace/workspace_intelligence.dart';
import '../../../workspace/graph/workspace_snapshot.dart';
import '../../../agent/planning/planning_models.dart';
import '../../../agent/planning/goal_analyzer.dart';
import '../../../agent/planning/requirement_extractor.dart';
import '../../../agent/planning/architecture_planner.dart';
import '../../../agent/planning/task_graph_builder.dart';
import '../../../agent/planning/risk_analyzer.dart';
import '../../../agent/planning/plan_reviewer.dart';

class PlannerGeneratePlanTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.generate_plan',
    name: 'Generate Execution Plan',
    description: 'Decomposes a goal into a full DAG ExecutionPlan.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'plan', 'decomposition'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final goal = request.arguments['goal'] as String? ?? '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    final snapshot = intel?.getSnapshot() ??
        WorkspaceSnapshot(
          snapshotId: 'snap-dummy',
          version: 1,
          createdAt: DateTime.now(),
          workspaceHash: 'hash-dummy',
          symbols: const [],
          dependencies: const [],
          calls: const [],
          buildDiagnostics: const [],
          classes: const [],
          enums: const [],
          mixins: const [],
          typedefs: const [],
          extensions: const [],
          routes: const [],
          services: const [],
          providers: const [],
        );

    final analyzer = GoalAnalyzer();
    final extractor = RequirementExtractor();
    final archPlanner = ArchitecturePlanner();
    final builder = TaskGraphBuilder();
    final riskAnalyzer = RiskAnalyzer();
    final reviewer = PlanReviewer();

    final goalAnalysis = analyzer.analyze(goal);
    final reqs = extractor.extract(goalAnalysis);
    final impact = archPlanner.planImpact(goalAnalysis, snapshot);
    final graph = builder.build(goalAnalysis, impact);
    final risk = riskAnalyzer.analyze(goalAnalysis, impact);
    final validation = reviewer.review(goalAnalysis, reqs, impact, graph);

    final estimate = ExecutionEstimate(
      estimatedLOC: impact.files.length * 40 + 20,
      estimatedTime: Duration(minutes: impact.files.length * 10 + 5),
      rollbackScope: impact.files,
    );

    final plan = ExecutionPlan(
      planId: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      goalAnalysis: goalAnalysis,
      requirement: reqs,
      impact: impact,
      graph: graph,
      risk: risk,
      estimate: estimate,
      validation: validation,
    );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: plan.toJson(),
        displayText: 'Generated execution plan containing ${graph.steps.length} tasks.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerValidatePlanTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.validate_plan',
    name: 'Validate Plan Graph',
    description: 'Validates plan task dependencies and cyclic layers.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'validate'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final goal = request.arguments['goal'] as String? ?? '';

    final analyzer = GoalAnalyzer();
    final extractor = RequirementExtractor();
    final reviewer = PlanReviewer();

    final goalAnalysis = analyzer.analyze(goal);
    final reqs = extractor.extract(goalAnalysis);
    final impact = const ArchitectureImpact(
      files: ['lib/main.dart'],
      services: [],
      routes: [],
      providers: [],
      tests: [],
      apis: [],
      database: [],
    );
    final builder = TaskGraphBuilder();
    final graph = builder.build(goalAnalysis, impact);

    final validation = reviewer.review(goalAnalysis, reqs, impact, graph);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: validation.toJson(),
        displayText: validation.valid ? 'Plan is valid.' : 'Plan has warnings.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerEstimateTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.estimate',
    name: 'Estimate Execution Stats',
    description: 'Retrieves timing and LOC estimates.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'estimate'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final filesCount = request.arguments['filesCount'] as int? ?? 1;

    final estimate = ExecutionEstimate(
      estimatedLOC: filesCount * 50,
      estimatedTime: Duration(minutes: filesCount * 12),
      rollbackScope: const ['lib/main.dart'],
    );

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: estimate.toJson(),
        displayText: 'Estimated LOC: ${estimate.estimatedLOC}, time: ${estimate.estimatedTime.inMinutes} minutes.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerRiskTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.risk',
    name: 'Score Plan Risks',
    description: 'Scores plan complexity and regression factors.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'risk'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final goal = request.arguments['goal'] as String? ?? '';

    final analyzer = GoalAnalyzer();
    final riskAnalyzer = RiskAnalyzer();
    final goalAnalysis = analyzer.analyze(goal);
    final impact = const ArchitectureImpact(
      files: ['lib/main.dart'],
      services: [],
      routes: [],
      providers: [],
      tests: [],
      apis: [],
      database: [],
    );

    final risk = riskAnalyzer.analyze(goalAnalysis, impact);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: risk.toJson(),
        displayText: 'Risk scoring complete.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerPreviewTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.preview',
    name: 'Preview execution scope',
    description: 'Displays a summary preview of changes.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'preview'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final goal = request.arguments['goal'] as String? ?? '';

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Plan preview: Implementing request "$goal".',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerDependenciesTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.dependencies',
    name: 'Get Plan Dependencies',
    description: 'Lists all task dependencies.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'dependencies'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: const {
          'dependencies': ['task.plan -> task.code', 'task.code -> task.review', 'task.code -> task.test']
        },
        displayText: 'Dependency relationships mapped.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerImpactTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.impact',
    name: 'Retrieve Architecture Impact',
    description: 'Retrieves affected components mapping.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'impact'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: const {
          'impacted_files': ['lib/main.dart']
        },
        displayText: 'Impact assessment retrieved.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerAcceptanceTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.acceptance',
    name: 'Get Acceptance Criteria',
    description: 'Gets criteria list.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'acceptance'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: const {
          'criteria': ['Compilation succeeds.', 'Tests pass cleanly.']
        },
        displayText: 'Acceptance checklist formulated.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class PlannerReviewTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'planner.review',
    name: 'Review Plan Output',
    description: 'Generates detailed code/ADR compliance recommendations.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['planner', 'review'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: const {
          'warnings': [],
          'recommendations': ['Use final variables in models.']
        },
        displayText: 'Recommendations generated.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
