import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/generation/code_generation_engine.dart';
import 'package:indiverse_developer_platform/core/agent/generation/file_generator.dart';
import 'package:indiverse_developer_platform/core/agent/generation/patch_builder.dart';
import 'package:indiverse_developer_platform/core/agent/generation/generation_validator.dart';
import 'package:indiverse_developer_platform/core/agent/generation/review_engine.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/generation_tools.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
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
  group('Sprint 22.2 - Autonomous Code Generation Engine Tests', () {
    late CodeGenerationEngine engine;
    late FileGenerator generator;
    late PatchBuilder patchBuilder;
    late ValidationPipeline validationPipeline;
    late ReviewEngine reviewEngine;

    setUp(() {
      engine = CodeGenerationEngine();
      generator = const FileGenerator();
      patchBuilder = const PatchBuilder();
      validationPipeline = ValidationPipeline();
      reviewEngine = const ReviewEngine();

      GenerationEngineRegistry.clear();
      GenerationEngineRegistry.register('test-ws', engine);
    });

    test('FileGenerator correctly produces GeneratedPatch objects', () async {
      final patch = await generator.generatePatch(
        filePath: 'lib/controllers/auth_controller.dart',
        originalText: 'class AuthController {}',
        generatedText: 'class AuthController {\n  void login() {}\n}',
      );

      expect(patch.filePath, equals('lib/controllers/auth_controller.dart'));
      expect(patch.generatedText, contains('void login()'));
      expect(patch.edits, hasLength(1));
    });

    test('PatchBuilder maps GeneratedPatch lists to WorkspaceEdit structures', () async {
      final patch = await generator.generatePatch(
        filePath: 'lib/main.dart',
        originalText: 'void main() {}',
        generatedText: 'void main() { runApp(); }',
      );

      final workspaceEdit = patchBuilder.buildWorkspaceEdit([patch]);
      expect(workspaceEdit.changes, contains('lib/main.dart'));
      expect(workspaceEdit.changes['lib/main.dart']!, hasLength(1));
    });

    test('ValidationPipeline flags syntax, import, and clean architecture errors', () async {
      final invalidSyntaxPatch = await generator.generatePatch(
        filePath: 'lib/invalid.dart',
        originalText: '',
        generatedText: 'void run() { invalid syntax',
      );
      final syntaxErrors = await validationPipeline.run(invalidSyntaxPatch);
      expect(syntaxErrors, contains('Syntax error: dangling brackets detected.'));

      final invalidArchitecturePatch = await generator.generatePatch(
        filePath: 'lib/domain/entities/user.dart',
        originalText: '',
        generatedText: 'import "package:flutter/widgets.dart";\nclass User {}',
      );
      final archErrors = await validationPipeline.run(invalidArchitecturePatch);
      expect(archErrors, contains('Clean Architecture Warning: Domain layer must not import UI packages.'));
    });

    test('ReviewEngine evaluates performance, security, and generates decisions', () async {
      final securePatch = await generator.generatePatch(
        filePath: 'lib/service.dart',
        originalText: '',
        generatedText: 'class SecureService {}',
      );

      final reviewSecure = await reviewEngine.review([securePatch]);
      expect(reviewSecure.securityScore, equals(9.5));
      expect(reviewSecure.overallDecision, equals('Approve'));

      final insecurePatch = await generator.generatePatch(
        filePath: 'lib/service.dart',
        originalText: '',
        generatedText: 'const password = "12345";',
      );

      final reviewInsecure = await reviewEngine.review([insecurePatch]);
      expect(reviewInsecure.securityScore, equals(4.0));
      expect(reviewInsecure.overallDecision, equals('Regenerate'));
    });

    test('Generator tools generate, patch, review, and rollback successfully', () async {
      final registry = TestToolRegistry();
      registry.register(GeneratorGenerateTool());
      registry.register(GeneratorPatchTool());
      registry.register(GeneratorValidateTool());
      registry.register(GeneratorReviewTool());
      registry.register(GeneratorRollbackTool());

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
        conversationId: 'conv-gen',
        requestId: 'req-gen',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestGenerate = const ToolCallRequest(
        toolCallId: 'call-gen',
        toolName: 'generator.generate',
        arguments: {'goal': 'Build OAuth service.'},
      );

      final resGenerate = await service.execute(requestGenerate, context);
      expect(resGenerate.success, isTrue);

      final dataGen = resGenerate.output.data as Map<String, dynamic>;
      expect(dataGen['patches'], hasLength(1));

      final requestRollback = const ToolCallRequest(
        toolCallId: 'call-roll',
        toolName: 'generator.rollback',
        arguments: {},
      );

      final resRollback = await service.execute(requestRollback, context);
      expect(resRollback.success, isTrue);
    });
  });
}
