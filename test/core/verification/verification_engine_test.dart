import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/generation/generation_models.dart';
import 'package:indiverse_developer_platform/core/agent/verification/verification_models.dart';
import 'package:indiverse_developer_platform/core/agent/verification/diagnostics_parser.dart';
import 'package:indiverse_developer_platform/core/agent/verification/verification_engine.dart';
import 'package:indiverse_developer_platform/core/agent/verification/repair_planner.dart';
import 'package:indiverse_developer_platform/core/agent/verification/self_healing_engine.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/verification_tools.dart';
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
import 'package:indiverse_developer_platform/core/diagnostics/diagnostic_models.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';

class TestToolRegistry extends ToolRegistry {}

class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 22.3 - Autonomous Verification & Self-Healing Tests', () {
    late DiagnosticsParser parser;
    late RepairPlanner repairPlanner;

    setUp(() {
      parser = DiagnosticsParser();
      repairPlanner = const RepairPlanner();
      VerificationEngineRegistry.clear();
    });

    test('DiagnosticsParser parses standard dart analyze logs correctly', () {
      const mockLog =
          'info - lib/core/service.dart:15:3 - Unused local variable - unused_variable\n';
      final issues = parser.parse(mockLog, origin: 'analyzer');

      expect(issues, hasLength(1));
      expect(issues.first.severity, equals('info'));
      expect(issues.first.file, equals('lib/core/service.dart'));
      expect(issues.first.range.start.line, equals(15));
      expect(issues.first.range.start.column, equals(3));
      expect(issues.first.code, equals('unused_variable'));
    });

    test('DiagnosticsParser handles fallback compile/test failures', () {
      const mockFailureLog = 'Compilation failed: unresolved identifier';
      final issues = parser.parse(mockFailureLog, origin: 'compiler');

      expect(issues, hasLength(1));
      expect(issues.first.severity, equals('error'));
      expect(issues.first.code, equals('EXECUTION_FAILURE'));
    });

    test('RepairPlanner returns smallest scope based on issue dispersion', () {
      // 1. Single issue with narrow line range
      final issue1 = const VerificationIssue(
        severity: 'error',
        origin: 'analyzer',
        file: 'lib/main.dart',
        range: Range(
            start: Position(line: 5, column: 1),
            end: Position(line: 5, column: 5)),
        code: 'err',
        message: 'msg',
        fixHint: '',
      );
      final issue2 = const VerificationIssue(
        severity: 'error',
        origin: 'analyzer',
        file: 'lib/main.dart',
        range: Range(
            start: Position(line: 8, column: 1),
            end: Position(line: 8, column: 5)),
        code: 'err',
        message: 'msg',
        fixHint: '',
      );

      final scopeLines = repairPlanner.planRepairScope([issue1, issue2]);
      expect(scopeLines, equals(RepairScope.lines));

      // 2. Single file but large line dispersion
      final issue3 = const VerificationIssue(
        severity: 'error',
        origin: 'analyzer',
        file: 'lib/main.dart',
        range: Range(
            start: Position(line: 30, column: 1),
            end: Position(line: 30, column: 5)),
        code: 'err',
        message: 'msg',
        fixHint: '',
      );

      final scopeFile = repairPlanner.planRepairScope([issue1, issue3]);
      expect(scopeFile, equals(RepairScope.file));

      // 3. Multi-file issues
      final issueOtherFile = const VerificationIssue(
        severity: 'error',
        origin: 'analyzer',
        file: 'lib/other.dart',
        range: Range(
            start: Position(line: 5, column: 1),
            end: Position(line: 5, column: 5)),
        code: 'err',
        message: 'msg',
        fixHint: '',
      );

      final scopeProject =
          repairPlanner.planRepairScope([issue1, issueOtherFile]);
      expect(scopeProject, equals(RepairScope.entireProject));
    });

    test(
        'SelfHealingEngine executes state transitions and retries up to maxRetries',
        () async {
      final runner = LocalVerificationRunner(
        mockAnalyzeOutput:
            'error - lib/main.dart:5:2 - Invalid type - type_error',
      );
      final engine = VerificationEngine(runner: runner);
      final selfHealing =
          SelfHealingEngine(verificationEngine: engine, maxRetries: 3);

      var generatorCalled = 0;
      final finalReport = await selfHealing.runSelfHealingLoop(
        initialPatches: const [],
        repairGenerator: (scope, issues) async {
          generatorCalled++;
          return [
            const GeneratedPatch(
              filePath: 'lib/main.dart',
              originalText: '',
              generatedText: 'void main() {}',
              edits: [],
            )
          ];
        },
      );

      // Loops 3 times and fails because mock runner output is static/failed
      expect(generatorCalled, equals(3));
      expect(finalReport.status, equals(VerificationStatus.failed));
      expect(selfHealing.state, equals(SelfHealingState.failed));
      expect(finalReport.metrics.retries, equals(3));
    });

    test('Verification Tools execute properly via ToolExecutionService',
        () async {
      final runner = LocalVerificationRunner();
      final engine = VerificationEngine(runner: runner);
      VerificationEngineRegistry.register('test-ws', engine);

      final registry = TestToolRegistry();
      registry.register(VerifyAnalyzeTool());
      registry.register(VerifyCompileTool());
      registry.register(VerifyTestTool());
      registry.register(VerifyReportTool());

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
        conversationId: 'conv-verify',
        requestId: 'req-verify',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestAnalyze = const ToolCallRequest(
        toolCallId: 'call-analyze',
        toolName: 'verify.analyze',
        arguments: {},
      );

      final resAnalyze = await service.execute(requestAnalyze, context);
      expect(resAnalyze.success, isTrue);

      final requestReport = const ToolCallRequest(
        toolCallId: 'call-report',
        toolName: 'verify.report',
        arguments: {},
      );

      final resReport = await service.execute(requestReport, context);
      expect(resReport.success, isTrue);
    });
  });
}
