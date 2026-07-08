import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/features/chat/controllers/chat_controller.dart';
import 'package:studio_ui/features/chat/widgets/tool_call_widget.dart';
import 'package:studio_ui/models/ai_models.dart';
import 'package:studio_ui/core/services/ai_service.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';

class FakeToolsAIService extends AIService {
  final StreamController<AIStreamEvent> streamController;
  final List<Map<String, dynamic>> sentDecisions = [];

  FakeToolsAIService(this.streamController) : super(serverUrl: '');

  @override
  Future<List<Map<String, dynamic>>> getProviders() async {
    return [
      {'id': 'mock-ai', 'name': 'Mock AI'},
    ];
  }

  @override
  Future<List<AIModel>> getModels() async {
    return [
      const AIModel(
        id: 'mock-pro',
        name: 'Mock Pro',
        provider: 'mock-ai',
        contextWindow: 1000,
        supportsVision: false,
        supportsTools: true,
        supportsReasoning: false,
        supportsJsonMode: false,
        supportsStreaming: true,
      ),
    ];
  }

  @override
  Stream<AIStreamEvent> chatStream({
    required ConversationSession session,
    String? activeFilePath,
    Map<String, String>? variables,
    int? maxContextTokens,
    String? requestId,
  }) {
    return streamController.stream;
  }

  @override
  Future<bool> sendPermissionResponse({
    required String toolCallId,
    required String decision,
  }) async {
    sentDecisions.add({'toolCallId': toolCallId, 'decision': decision});
    return true;
  }
}

void main() {
  group('Sprint 21.5 - Client Tool Calling Integration Tests', () {
    test(
      'Verify tool call stream events update controller state correctly',
      () async {
        final streamController = StreamController<AIStreamEvent>();
        final fakeService = FakeToolsAIService(streamController);
        final controller = ChatController(
          aiService: fakeService,
          workspace: 'test',
        );

        await controller.initialize();
        expect(controller.state.toolCalls, isEmpty);

        // Send prompt to set up stream
        controller.sendPrompt('Run tool please');
        await Future.delayed(Duration.zero);

        final reqId = controller.requestMetricsMap.keys.first;

        // 1. Tool Permission Requested
        streamController.add(
          ToolPermissionRequestedEvent(
            requestId: reqId,
            timestamp: DateTime.now(),
            toolCallId: 'call-1',
            toolName: 'workspace.writeFile',
            arguments: {'path': 'a.txt', 'content': 'hello'},
          ),
        );
        await Future.delayed(Duration.zero);

        expect(controller.state.toolCalls.length, equals(1));
        expect(controller.state.toolCalls.first.toolCallId, equals('call-1'));
        expect(
          controller.state.toolCalls.first.status,
          equals(ToolCallStatus.pendingPermission),
        );

        // 2. Tool Call Started
        streamController.add(
          ToolCallStartedEvent(
            requestId: reqId,
            timestamp: DateTime.now(),
            toolCallId: 'call-1',
            toolName: 'workspace.writeFile',
            arguments: {'path': 'a.txt', 'content': 'hello'},
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          controller.state.toolCalls.first.status,
          equals(ToolCallStatus.running),
        );

        // 3. Tool Call Progress
        streamController.add(
          ToolCallProgressEvent(
            requestId: reqId,
            timestamp: DateTime.now(),
            toolCallId: 'call-1',
            message: 'Writing bytes...',
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          controller.state.toolCalls.first.progressMessage,
          equals('Writing bytes...'),
        );

        // 4. Tool Call Completed
        streamController.add(
          ToolCallCompletedEvent(
            requestId: reqId,
            timestamp: DateTime.now(),
            toolCallId: 'call-1',
            result: const ToolCallResult(
              success: true,
              output: ToolOutput(displayText: 'Success writing 5 bytes'),
              duration: Duration(milliseconds: 100),
            ),
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          controller.state.toolCalls.first.status,
          equals(ToolCallStatus.completed),
        );
        expect(
          controller.state.toolCalls.first.result?.output.displayText,
          equals('Success writing 5 bytes'),
        );
      },
    );

    test('Verify submitPermissionDecision invokes backend API', () async {
      final streamController = StreamController<AIStreamEvent>();
      final fakeService = FakeToolsAIService(streamController);
      final controller = ChatController(
        aiService: fakeService,
        workspace: 'test',
      );

      await controller.initialize();
      controller.sendPrompt('test');
      await Future.delayed(Duration.zero);

      // Add a pending permission tool call
      final reqId = controller.requestMetricsMap.keys.first;
      streamController.add(
        ToolPermissionRequestedEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          toolCallId: 'call-xyz',
          toolName: 'git.status',
          arguments: {},
        ),
      );
      await Future.delayed(Duration.zero);

      await controller.submitPermissionDecision(
        'call-xyz',
        PermissionDecision.allowOnce,
      );

      expect(fakeService.sentDecisions.length, equals(1));
      expect(fakeService.sentDecisions.first['toolCallId'], equals('call-xyz'));
      expect(fakeService.sentDecisions.first['decision'], equals('allowOnce'));
      expect(
        controller.state.toolCalls.first.status,
        equals(ToolCallStatus.running),
      );
    });

    testWidgets('Verify ToolCallWidget UI rendering for different statuses', (
      WidgetTester tester,
    ) async {
      final streamController = StreamController<AIStreamEvent>();
      final fakeService = FakeToolsAIService(streamController);
      final controller = ChatController(
        aiService: fakeService,
        workspace: 'test',
      );
      await controller.initialize();

      // Case 1: Running status
      final toolCallRunning = const ToolCallState(
        toolCallId: 'call-running',
        toolName: 'workspace.search',
        arguments: {'query': 'PlatformSDK'},
        status: ToolCallStatus.running,
        progressMessage: 'Searching directories...',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolCallWidget(
              toolCall: toolCallRunning,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Tool: workspace.search'), findsOneWidget);
      expect(find.text('Searching directories...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Case 2: Completed status
      final toolCallCompleted = const ToolCallState(
        toolCallId: 'call-completed',
        toolName: 'workspace.search',
        arguments: {'query': 'PlatformSDK'},
        status: ToolCallStatus.completed,
        result: ToolCallResult(
          success: true,
          output: ToolOutput(displayText: 'Found 5 files'),
          duration: Duration(milliseconds: 150),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolCallWidget(
              toolCall: toolCallCompleted,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Tool: workspace.search'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
