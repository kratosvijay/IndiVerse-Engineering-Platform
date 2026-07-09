import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/planning/planning_models.dart';
import 'package:indiverse_developer_platform/core/agent/planning/goal_analyzer.dart';
import 'package:indiverse_developer_platform/core/agent/planning/requirement_extractor.dart';
import 'package:indiverse_developer_platform/core/agent/planning/architecture_planner.dart';
import 'package:indiverse_developer_platform/core/agent/planning/task_graph_builder.dart';
import 'package:indiverse_developer_platform/core/agent/planning/risk_analyzer.dart';
import 'package:indiverse_developer_platform/core/agent/planning/plan_reviewer.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_graph.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_step.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/workspace_snapshot.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/workspace_symbol.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/planner_tools.dart';
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

class TestToolRegistry extends ToolRegistry {}
class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 22.1 - Autonomous Codebase Planning Tests', () {
    late GoalAnalyzer analyzer;
    late RequirementExtractor extractor;
    late ArchitecturePlanner archPlanner;
    late TaskGraphBuilder graphBuilder;
    late RiskAnalyzer riskAnalyzer;
    late PlanReviewer reviewer;
    late WorkspaceSnapshot dummySnapshot;

    setUp(() {
      analyzer = GoalAnalyzer();
      extractor = RequirementExtractor();
      archPlanner = ArchitecturePlanner();
      graphBuilder = TaskGraphBuilder();
      riskAnalyzer = RiskAnalyzer();
      reviewer = PlanReviewer();

      dummySnapshot = WorkspaceSnapshot(
        snapshotId: 'snap-1',
        version: 1,
        createdAt: DateTime.now(),
        workspaceHash: 'hash-1',
        symbols: const [
          WorkspaceSymbol(
            id: 'AuthService',
            name: 'AuthService',
            kind: SymbolKind.classSymbol,
            visibility: SymbolVisibility.public,
            filePath: 'lib/services/auth_service.dart',
            startLine: 10,
            endLine: 20,
            column: 1,
            annotations: const [],
            parentIds: const [],
            childrenIds: const [],
          ),
          WorkspaceSymbol(
            id: 'AuthRoute',
            name: 'AuthRoute',
            kind: SymbolKind.method,
            visibility: SymbolVisibility.public,
            filePath: 'lib/routes/auth_route.dart',
            startLine: 45,
            endLine: 55,
            column: 3,
            annotations: const [],
            parentIds: const [],
            childrenIds: const [],
          ),
        ],
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
    });

    test('GoalAnalyzer correctly classifies feature, bugfix, and doc prompts', () {
      final resFeature = analyzer.analyze('Implement OAuth user login page.');
      expect(resFeature.type, equals(GoalType.feature));
      expect(resFeature.priority, equals('Medium'));
      expect(resFeature.constraints, contains('Must enforce secure token handshake.'));

      final resBug = analyzer.analyze('Fix compiler diagnostic parsing error on main.dart.');
      expect(resBug.type, equals(GoalType.bugfix));
      expect(resBug.priority, equals('High'));

      final resDoc = analyzer.analyze('Update README file details.');
      expect(resDoc.type, equals(GoalType.documentation));
    });

    test('RequirementExtractor produces proper functional & nonfunctional conditions', () {
      final goalAnalysis = analyzer.analyze('Clean the repository architecture paths.');
      final requirements = extractor.extract(goalAnalysis);

      expect(requirements.functional, contains('Refactor modules to reuse shared utils.'));
      expect(requirements.nonFunctional, contains('Execution performance must not degrade.'));
    });

    test('ArchitecturePlanner detects affected paths using snapshot intelligence', () {
      final goalAnalysis = analyzer.analyze('Implement user authentication service.');
      final impact = archPlanner.planImpact(goalAnalysis, dummySnapshot);

      expect(impact.files, contains('lib/services/auth_service.dart'));
      expect(impact.services, contains('AuthService'));
      expect(impact.routes, contains('AuthRoute'));
    });

    test('TaskGraphBuilder maps planning DAG nodes with correct dependencies', () {
      final goalAnalysis = analyzer.analyze('Add settings page.');
      final impact = const ArchitectureImpact(
        files: ['lib/main.dart'],
        services: [],
        routes: [],
        providers: [],
        tests: [],
        apis: [],
        database: [],
      );

      final graph = graphBuilder.build(goalAnalysis, impact);
      expect(graph.steps, hasLength(5));

      final stepCode = graph.steps.firstWhere((s) => s.id == 'task.code');
      expect(stepCode.dependencies, contains('task.plan'));

      final stepDoc = graph.steps.firstWhere((s) => s.id == 'task.document');
      expect(stepDoc.dependencies, contains('task.review'));
      expect(stepDoc.dependencies, contains('task.test'));
    });

    test('RiskAnalyzer computes individual security, performance, regression categories', () {
      final goalAnalysis = analyzer.analyze('Optimize database calls performance under 200ms.');
      final impact = const ArchitectureImpact(
        files: ['lib/main.dart', 'lib/db.dart'],
        services: [],
        routes: [],
        providers: [],
        tests: [],
        apis: [],
        database: ['schema-migration'],
      );

      final risk = riskAnalyzer.analyze(goalAnalysis, impact);
      expect(risk.complexityScore, greaterThan(1.0));
      expect(risk.performanceRisk, greaterThan(1.0));
      expect(risk.migrationRisk, greaterThan(1.0));
    });

    test('PlanReviewer detects invalid dependency loops and code warnings', () {
      // Loop: stepA depends on stepB, stepB depends on stepA
      final invalidGraph = const TaskGraph(
        id: 'graph-loop',
        goal: 'Loop testing',
        steps: [
          TaskStep(id: 'step-a', title: 'Step A', dependencies: ['step-b']),
          TaskStep(id: 'step-b', title: 'Step B', dependencies: ['step-a']),
        ],
      );

      final validation = reviewer.review(
        const GoalAnalysis(
          goal: 'Loop test',
          type: GoalType.feature,
          constraints: [],
          acceptanceCriteria: [],
          priority: 'Medium',
        ),
        const Requirement(functional: [], nonFunctional: [], constraints: [], assumptions: []),
        const ArchitectureImpact(
          files: ['lib/main.dart'],
          services: ['AuthService_widget'], // widget name in service leads to warning
          routes: [],
          providers: [],
          tests: [],
          apis: [],
          database: [],
        ),
        invalidGraph,
      );

      expect(validation.valid, isFalse);
      expect(validation.warnings, contains('Cyclic dependencies detected in task graph!'));
      expect(validation.warnings, contains('Possible Clean Architecture violation: service matches widget name.'));
    });

    test('Planner generate, validate, and estimate tools run successfully', () async {
      final registry = TestToolRegistry();
      registry.register(PlannerGeneratePlanTool());
      registry.register(PlannerValidatePlanTool());
      registry.register(PlannerEstimateTool());
      registry.register(PlannerRiskTool());
      registry.register(PlannerPreviewTool());

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
        conversationId: 'conv-planning',
        requestId: 'req-planning',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestGenerate = ToolCallRequest(
        toolCallId: 'call-gen',
        toolName: 'planner.generate_plan',
        arguments: const {'goal': 'Add secure token database log.'},
      );

      final resGenerate = await service.execute(requestGenerate, context);
      expect(resGenerate.success, isTrue);
      final genData = resGenerate.output.data as Map<String, dynamic>;
      expect(genData['planId'], isNotNull);
      expect(genData['risk'], isNotNull);

      final requestValidate = ToolCallRequest(
        toolCallId: 'call-val',
        toolName: 'planner.validate_plan',
        arguments: const {'goal': 'Add route.'},
      );

      final resValidate = await service.execute(requestValidate, context);
      expect(resValidate.success, isTrue);

      final requestEstimate = ToolCallRequest(
        toolCallId: 'call-est',
        toolName: 'planner.estimate',
        arguments: const {'filesCount': 3},
      );

      final resEstimate = await service.execute(requestEstimate, context);
      expect(resEstimate.success, isTrue);
      final estData = resEstimate.output.data as Map<String, dynamic>;
      expect(estData['estimatedLOC'], equals(150));
    });
  });
}
