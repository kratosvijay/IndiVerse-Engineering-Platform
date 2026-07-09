import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/review/review_models.dart';
import 'package:indiverse_developer_platform/core/agent/review/engineering_review_engine.dart';
import 'package:indiverse_developer_platform/core/agent/review/decision_engine.dart';
import 'package:indiverse_developer_platform/core/agent/review/confidence_engine.dart';
import 'package:indiverse_developer_platform/core/agent/review/human_approval_engine.dart';
import 'package:indiverse_developer_platform/core/agent/review/project_convention_engine.dart';
import 'package:indiverse_developer_platform/core/agent/review/architecture_diff.dart';
import 'package:indiverse_developer_platform/core/agent/review/explainability_engine.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/review_tools.dart';
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
  group('Sprint 22.8 - Engineering Intelligence & Human Collaboration Tests', () {
    test('EngineeringReviewEngine runs analyzers and returns scores', () async {
      final engine = EngineeringReviewEngine(
        analyzers: [
          ArchitectureAnalyzer(),
          SecurityAnalyzer(),
          PerformanceAnalyzer(),
          MaintainabilityAnalyzer(),
          TestabilityAnalyzer(),
          DocumentationAnalyzer(),
        ],
      );

      const sourceCode = '''
        class UserRepository extends GetxController {
          final String api_key = "abc123secret";
        }
      ''';

      final report = await engine.runReview(sourceCode);
      expect(report.overallScore, lessThan(10.0));
      expect(report.metrics[ReviewCategory.security]?.score, lessThan(10.0));
    });

    test('ConfidenceEngine aggregates hierarchical subsystems metrics', () {
      const engine = ConfidenceEngine();
      final report = engine.calculateHierarchicalConfidence(
        planning: 0.90,
        generation: 0.85,
        verification: 0.95,
        repair: 0.80,
        deployment: 0.90,
        knowledge: 0.85,
        reflection: 0.85,
      );

      expect(report.overall, closeTo(0.871, 0.01));
    });

    test('DecisionEngine evaluates actions based on context parameters', () {
      final engine = DecisionEngine();
      const confidence = ConfidenceScoreReport(
        planning: 0.9,
        generation: 0.9,
        verification: 0.9,
        repair: 0.9,
        deployment: 0.9,
        knowledge: 0.9,
        reflection: 0.9,
        overall: 0.9,
      );
      const review = ReviewReport(metrics: {}, overallScore: 8.5);

      final contextSafe = const DecisionContext(
        review: review,
        confidence: confidence,
        verificationReport: {},
        estimatedLoc: 50,
        hasSecurityRisk: false,
      );

      final decision1 = engine.evaluate(contextSafe);
      expect(decision1.action, equals(DecisionAction.execute));

      final contextRisky = const DecisionContext(
        review: review,
        confidence: confidence,
        verificationReport: {},
        estimatedLoc: 600,
        hasSecurityRisk: false,
      );

      final decision2 = engine.evaluate(contextRisky);
      expect(decision2.action, equals(DecisionAction.askUser));
    });

    test('HumanApprovalEngine gates and processes outcomes', () {
      final engine = HumanApprovalEngine(policies: [RiskPolicy(), SecurityPolicy()]);
      const request = ApprovalRequest(
        requestId: 'req-1',
        title: 'Large Code Change',
        reason: 'Adding authentication services classes.',
        riskLevel: 'high',
        affectedFiles: ['lib/auth.dart'],
        estimatedLoc: 1200,
        confidence: 0.95,
        status: ApprovalStatus.pending,
        recommendedAction: 'Verify auth configs.',
      );

      engine.submitRequest(request);
      expect(engine.requests.length, equals(1));

      final processed = engine.processOutcome('req-1', ApprovalOutcome.approve);
      expect(processed.status, equals(ApprovalStatus.approved));
    });

    test('ProjectConventionEngine classifies state managers and view styles', () {
      final engine = ProjectConventionEngine();
      const code = '''
        class AuthController extends GetxController {}
        class AuthScreen extends StatelessWidget {}
      ''';

      final conventions = engine.scan(code);
      expect(conventions.length, equals(2));
      expect(conventions.first.type, equals(ConventionType.stateManagement));
    });

    test('ArchitectureDiffCalculator detects added and removed class paths', () {
      const calc = ArchitectureDiffCalculator();
      final diff = calc.calculateDiff(
        oldClasses: const ['AuthService'],
        newClasses: const ['AuthService', 'BillingService'],
        oldRoutes: const ['/login'],
        newRoutes: const ['/login', '/billing'],
      );

      expect(diff.addedServices, contains('BillingService'));
      expect(diff.addedRoutes, contains('/billing'));
    });

    test('ExplainabilityEngine tracks decision histories', () {
      final engine = ExplainabilityEngine();
      const trace = ExplainabilityTrace(
        actionId: 'action-1',
        whyExplanation: 'Upgraded dependencies to resolve CVEs.',
        alternativesConsidered: ['Keep using old version'],
        tradeoffs: {},
        referenceSymbols: [],
      );

      engine.logTrace(trace);
      final retrieved = engine.getTrace('action-1');
      expect(retrieved?.whyExplanation, contains('CVEs'));
    });

    test('Review Tools execute via ToolExecutionService successfully', () async {
      final registry = TestToolRegistry();
      registry.register(ReviewArchitectureTool());
      registry.register(ReviewSecurityTool());
      registry.register(ReviewPerformanceTool());
      registry.register(ReviewMaintainabilityTool());
      registry.register(ReviewTestabilityTool());
      registry.register(ReviewStyleTool());
      registry.register(ReviewDocumentationTool());
      registry.register(ReviewSummaryTool());
      registry.register(ReviewExplainTool());
      registry.register(ReviewCompareTool());
      registry.register(DecisionExplainTool());
      registry.register(DecisionHistoryTool());
      registry.register(DecisionReplayTool());
      registry.register(DecisionCompareTool());
      registry.register(ApprovalPendingTool());
      registry.register(ApprovalRespondTool());
      registry.register(ApprovalHistoryTool());
      registry.register(ApprovalCancelTool());
      registry.register(ConventionsScanTool());
      registry.register(ConventionsLearnTool());
      registry.register(ConventionsExportTool());
      registry.register(ConventionsImportTool());
      registry.register(ArchitectureDiffTool());
      registry.register(ConfidenceReportTool());
      registry.register(ConfidenceTimelineTool());

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
        conversationId: 'conv-review',
        requestId: 'req-review',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestSummary = const ToolCallRequest(
        toolCallId: 'call-summary',
        toolName: 'review.summary',
        arguments: {},
      );

      final resSummary = await service.execute(requestSummary, context);
      expect(resSummary.success, isTrue);

      final requestConfidence = const ToolCallRequest(
        toolCallId: 'call-confidence',
        toolName: 'confidence.report',
        arguments: {},
      );

      final resConfidence = await service.execute(requestConfidence, context);
      expect(resConfidence.success, isTrue);
    });
  });
}
