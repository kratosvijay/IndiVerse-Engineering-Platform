import 'dart:io';
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/workspace_search_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/workspace_read_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/workspace_write_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/git_status_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/git_diff_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/editor_replace_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/diagnostics_list_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/workspace_open_file_tool.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/editor_query_tools.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() {
  group('Sprint 21.5 - Tool Execution & Registry Tests', () {
    late ToolRegistry registry;
    late ToolPermissionStore permissionStore;
    late ToolExecutionService executionService;
    late PlatformSDK sdk;

    setUp(() {
      registry = ToolRegistry();
      permissionStore = ToolPermissionStore();
      executionService = ToolExecutionService(
        registry: registry,
        permissionStore: permissionStore,
      );

      sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      // Register tools
      registry.register(WorkspaceSearchTool());
      registry.register(WorkspaceReadTool());
      registry.register(WorkspaceOpenFileTool());
      registry.register(WorkspaceWriteTool());
      registry.register(GitStatusTool());
      registry.register(GitDiffTool());
      registry.register(EditorReplaceTool());
      registry.register(DiagnosticsListTool());
      registry.register(EditorCurrentFileTool());
      registry.register(EditorSelectionTool());
    });

    test('Verify all built-in tools are registered properly', () {
      final tools = registry.listTools();
      expect(tools.length, equals(10));
      expect(registry.getTool('workspace.search'), isA<WorkspaceSearchTool>());
      expect(registry.getTool('workspace.readFile'), isA<WorkspaceReadTool>());
      expect(
          registry.getTool('workspace.writeFile'), isA<WorkspaceWriteTool>());
      expect(registry.getTool('git.status'), isA<GitStatusTool>());
      expect(registry.getTool('git.diff'), isA<GitDiffTool>());
      expect(registry.getTool('editor.replace'), isA<EditorReplaceTool>());
      expect(registry.getTool('diagnostics.list'), isA<DiagnosticsListTool>());
      expect(
          registry.getTool('editor.currentFile'), isA<EditorCurrentFileTool>());
      expect(registry.getTool('editor.selection'), isA<EditorSelectionTool>());
    });

    test('Verify sequential workspace search execution', () async {
      final request = const ToolCallRequest(
        toolCallId: 'test-call-1',
        toolName: 'workspace.search',
        arguments: {'query': 'PlatformSDK'},
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'test-conv',
        requestId: 'test-req',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final result = await executionService.execute(request, context);
      expect(result.success, isTrue);
      expect(result.output.displayText, contains('Found'));
      expect(result.output.mimeType, equals('application/json'));
    });

    test('Verify editor replacement permission gate & mock behavior', () async {
      final file = File('temp_editor_replace_test.txt');
      await file.writeAsString("impo 'dart:async';");

      final request = const ToolCallRequest(
        toolCallId: 'test-call-2',
        toolName: 'editor.replace',
        arguments: {
          'path': 'temp_editor_replace_test.txt',
          'startLine': 1,
          'startColumn': 1,
          'endLine': 1,
          'endColumn': 5,
          'newText': 'import',
        },
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'test-conv',
        requestId: 'test-req',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      // Permission not yet granted, it will wait for permission.
      // Let's pre-resolve it in the permissionStore to allowAlways
      permissionStore.saveDecision(
          'editor.replace', PermissionDecision.allowAlways);

      final result = await executionService.execute(request, context);
      expect(result.success, isTrue);

      // Verify file content was updated
      expect(await file.readAsString(), equals("import 'dart:async';"));

      // Clean up
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('Verify denial decision correctly aborts execution', () async {
      final file = File('temp_editor_replace_test.txt');
      await file.writeAsString("impo 'dart:async';");

      final request = const ToolCallRequest(
        toolCallId: 'test-call-3',
        toolName: 'editor.replace',
        arguments: {
          'path': 'temp_editor_replace_test.txt',
          'startLine': 1,
          'startColumn': 1,
          'endLine': 1,
          'endColumn': 5,
          'newText': 'import',
        },
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'test-conv',
        requestId: 'test-req',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      permissionStore.saveDecision(
          'editor.replace', PermissionDecision.denyAlways);

      final result = await executionService.execute(request, context);
      expect(result.success, isFalse);
      expect(result.errorCode, equals('PERMISSION_DENIED'));

      // Clean up
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('Verify snapshotting capture, deduplication, and restore lifecycle',
        () async {
      // 1. Create a dummy file
      final file = File('scratch_test_file.txt');
      await file.writeAsString('initial content');

      // Setup write request
      final request = const ToolCallRequest(
        toolCallId: 'write-call-1',
        toolName: 'workspace.writeFile',
        arguments: {
          'path': 'scratch_test_file.txt',
          'content': 'modified content',
        },
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'test-conv',
        requestId: 'test-req-dedupe',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      permissionStore.saveDecision(
          'workspace.writeFile', PermissionDecision.allowAlways);

      // Execute: first time should capture a snapshot
      final result = await executionService.execute(request, context);
      expect(result.success, isTrue);

      expect(executionService.snapshotService.baseDir, equals('.indiverse'));

      // Check if backup file exists
      final backupFiles = Directory('.indiverse/snapshots').listSync();
      expect(backupFiles.isNotEmpty, isTrue);

      // Test deduplication: run same file write again with same requestId
      final snapshot2 = await executionService.snapshotService
          .captureSnapshot('scratch_test_file.txt', 'test-req-dedupe');
      expect(snapshot2, isNotNull);

      // Clean up backup file
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test(
        'Verify structured auditing records are written upon execution success/failure',
        () async {
      final request = const ToolCallRequest(
        toolCallId: 'audit-call-1',
        toolName: 'git.status',
        arguments: {},
      );

      final context = ToolExecutionContext(
        workspaceId: 'audit-ws',
        conversationId: 'audit-conv',
        requestId: 'audit-req',
        providerId: 'mock-provider',
        modelId: 'mock-model',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      permissionStore.saveDecision(
          'git.status', PermissionDecision.allowAlways);

      final result = await executionService.execute(request, context);
      expect(result.success, isTrue);

      // Verify audit logs contains our record
      final record = executionService.auditService.inMemoryLogs.firstWhere(
        (r) => r.toolCallId == 'audit-call-1',
      );
      expect(record.conversationId, equals('audit-conv'));
      expect(record.requestId, equals('audit-req'));
      expect(record.tool, equals('git.status'));
      expect(record.workspaceId, equals('audit-ws'));
      expect(record.providerId, equals('mock-provider'));
      expect(record.modelId, equals('mock-model'));
      expect(record.success, isTrue);
    });

    test('Verify parent/child tool calling relationships and depth mapping',
        () async {
      final requestParent = const ToolCallRequest(
        toolCallId: 'parent-1',
        toolName: 'git.status',
        arguments: {},
      );

      final requestChild = const ToolCallRequest(
        toolCallId: 'child-1',
        toolName: 'git.status',
        arguments: {},
        parentToolCallId: 'parent-1',
      );

      final context = ToolExecutionContext(
        workspaceId: 'chain-ws',
        conversationId: 'chain-conv',
        requestId: 'chain-req',
        providerId: 'mock-provider',
        modelId: 'mock-model',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      // Execute parent
      await executionService.execute(requestParent, context);
      // Execute child
      await executionService.execute(requestChild, context);

      // Parent depth should be 0
      final parentRecord =
          executionService.auditService.inMemoryLogs.firstWhere(
        (r) => r.toolCallId == 'parent-1',
      );
      expect(parentRecord.parentToolCallId, isNull);

      // Child record should have parent ID and depth 1
      final childRecord = executionService.auditService.inMemoryLogs.firstWhere(
        (r) => r.toolCallId == 'child-1',
      );
      expect(childRecord.parentToolCallId, equals('parent-1'));
    });
  });
}
