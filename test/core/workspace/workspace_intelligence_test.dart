import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_intelligence.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/workspace_symbol.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/dependency_graph.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/call_graph.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/workspace_snapshot.dart';
import 'package:indiverse_developer_platform/core/workspace/index/architecture_index.dart';
import 'package:indiverse_developer_platform/core/workspace/index/build_intelligence.dart';
import 'package:indiverse_developer_platform/core/workspace/discovery/dart_regex_parser.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_query_engine.dart';
import 'package:indiverse_developer_platform/core/workspace/context/providers/intelligence_context_providers.dart';
import 'package:indiverse_developer_platform/core/context/context_engine.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/workspace_intelligence_tools.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() {
  group('Sprint 21.8 - Workspace Intelligence Tests', () {
    const mockDartContent = '''
// Some comments
/// Documentation for AuthService
@Service
class AuthService {
  final UserProvider _provider;

  AuthService(this._provider);

  @Route
  Future<bool> login(String username, String password) async {
    final res = await _provider.verifyUser(username, password);
    super.logEvent("login_attempt");
    new AuthToken(res);
    return res;
  }
}
''';

    test('DartRegexParser extracts classes, methods, imports, and calls', () {
      final parser = DartRegexParser();
      final result = parser.parse('lib/services/auth_service.dart', mockDartContent);

      expect(result.symbols, isNotEmpty);
      
      final classSym = result.symbols.firstWhere((s) => s.kind == SymbolKind.classSymbol);
      expect(classSym.name, equals('AuthService'));
      expect(classSym.documentation, equals('Documentation for AuthService'));
      expect(classSym.annotations, contains('Service'));

      final methodSym = result.symbols.firstWhere((s) => s.kind == SymbolKind.method);
      expect(methodSym.name, equals('login'));
      expect(methodSym.annotations, contains('Route'));
      expect(methodSym.parentIds, contains(classSym.id));

      // Check extracted calls
      expect(result.calls, isNotEmpty);
      final normalCall = result.calls.firstWhere((c) => c['type'] == CallType.normal);
      expect(normalCall['callerId'], equals(methodSym.id));
      expect(normalCall['calleeId'], contains('verifyUser'));
    });

    test('DependencyGraph tracks dependencies, cycles, and shortest paths', () {
      final graph = DependencyGraph();
      graph.addDependency('lib/a.dart', 'lib/b.dart', DependencyType.importRelation);
      graph.addDependency('lib/b.dart', 'lib/c.dart', DependencyType.importRelation);

      expect(graph.dependenciesOf('lib/a.dart'), contains('lib/b.dart'));
      expect(graph.dependentsOf('lib/c.dart'), contains('lib/b.dart'));

      // Shortest path
      final path = graph.shortestPath('lib/a.dart', 'lib/c.dart');
      expect(path, equals(['lib/a.dart', 'lib/b.dart', 'lib/c.dart']));

      // Cycle detection
      expect(graph.hasCycles(), isFalse);
      graph.addDependency('lib/c.dart', 'lib/a.dart', DependencyType.importRelation);
      expect(graph.hasCycles(), isTrue);
    });

    test('CallGraph maps caller and callee nodes', () {
      final callGraph = CallGraph();
      callGraph.addCall('methodA', 'methodB', CallType.normal);
      callGraph.addCall('methodB', 'methodC', CallType.superCall);

      expect(callGraph.getCallees('methodA'), contains('methodB'));
      expect(callGraph.getCallers('methodC'), contains('methodB'));
    });

    test('WorkspaceIntelligence incremental indexing and querying works', () {
      final intel = WorkspaceIntelligence(
        workspaceId: 'test-ws',
        workspacePath: 'test_root',
      );

      // Clean check
      expect(intel.getSnapshot().symbols, isEmpty);

      // Index file first time
      final isModified1 = intel.indexFile('lib/services/auth_service.dart', mockDartContent);
      expect(isModified1, isTrue);
      
      final snap1 = intel.getSnapshot();
      expect(snap1.symbols, isNotEmpty);
      expect(snap1.version, equals(2));

      // Index second time with identical content (should skip)
      final isModified2 = intel.indexFile('lib/services/auth_service.dart', mockDartContent);
      expect(isModified2, isFalse);
      
      final snap2 = intel.getSnapshot();
      expect(snap2.version, equals(2)); // version did not increment

      // Querying tests
      final symbolResult = intel.findSymbol('AuthService');
      expect(symbolResult.items, isNotEmpty);
      expect(symbolResult.items.first.name, equals('AuthService'));

      final defResult = intel.findDefinition('login');
      expect(defResult.items, isNotEmpty);
      expect(defResult.items.first.name, equals('login'));
    });

    test('ContextProviders generate valid text snippets', () async {
      final intel = WorkspaceIntelligence(
        workspaceId: 'test-ws',
        workspacePath: 'test_root',
      );
      intel.indexFile('lib/services/auth_service.dart', mockDartContent);
      WorkspaceIntelligenceRegistry.register('test_root', intel);

      final archProvider = ArchitectureContextProvider();
      final contextReq = const ContextRequest(workspace: 'test_root', maxTokens: 1000);
      final frag = await archProvider.resolve(contextReq);

      expect(frag.content, contains('AuthService'));
      expect(frag.content, contains('Services'));
    });

    test('Workspace Intelligence tools execute correctly via ToolExecutionService', () async {
      final registry = ToolRegistry();
      final permissionStore = ToolPermissionStore();
      final executionService = ToolExecutionService(
        registry: registry,
        permissionStore: permissionStore,
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      registry.register(FindSymbolTool());
      registry.register(FindDefinitionTool());

      final intel = WorkspaceIntelligence(
        workspaceId: 'test-ws',
        workspacePath: 'test_root',
      );
      intel.indexFile('lib/services/auth_service.dart', mockDartContent);
      WorkspaceIntelligenceRegistry.register('test_root', intel);

      final request = ToolCallRequest(
        toolCallId: 'call-1',
        toolName: 'workspace.find_symbol',
        arguments: const {'query': 'AuthService'},
      );

      final context = ToolExecutionContext(
        workspaceId: 'test_root',
        conversationId: 'conv-1',
        requestId: 'req-1',
        providerId: 'provider-1',
        modelId: 'model-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final result = await executionService.execute(request, context);
      expect(result.success, isTrue);
      expect(result.output.displayText, contains('AuthService'));
    });
  });
}
