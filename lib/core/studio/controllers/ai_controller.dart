import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../providers/ai_provider.dart';
import '../../providers/ai_stream_events.dart';
import '../../providers/ai_provider_registry.dart';
import '../../conversation/conversation_manager.dart';
import '../../context/context_engine.dart';
import '../../prompt/prompt_pipeline.dart';
import '../../models/tool_call_models.dart';
import '../services/tool_execution_service.dart';
import '../services/tool_handler.dart';
import '../dto/api_response.dart';
import '../../../platform_sdk/platform_sdk.dart';

class AIController {
  final AIProviderRegistry registry;
  final ConversationManager conversationManager;
  final ContextEngine contextEngine;
  final ToolExecutionService toolExecutionService;
  final PlatformSDK sdk;
  final PromptBuilder promptBuilder = PromptBuilder();

  // Map to store active request cancel tokens
  final Map<String, CancellationToken> _activeRequests = {};

  AIController({
    required this.registry,
    required this.conversationManager,
    required this.contextEngine,
    required this.toolExecutionService,
    required this.sdk,
  });

  final Map<String, PromptTemplate> _templates = {
    'default': const PromptTemplate(
      systemTemplate:
          'You are IndiVerse Copilot, a helpful pair programming assistant. System variables: {{workspace}}',
      userTemplate: 'Help with: {{message}}',
    ),
    'explain': const PromptTemplate(
      systemTemplate:
          'You are an expert software engineer. Explain the code segment clearly.',
      userTemplate: 'Explain this code:\n{{message}}',
    ),
  };

  Future<void> handleChat(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

      final sessionJson = bodyJson['session'] as Map<String, dynamic>;
      final activeFilePath = bodyJson['activeFilePath'] as String?;
      final selectedCode = bodyJson['selectedCode'] as String?;
      final templateId = bodyJson['templateId'] as String? ?? 'default';
      final variables =
          Map<String, String>.from(bodyJson['variables'] as Map? ?? {});
      final maxContextTokens = bodyJson['maxContextTokens'] as int? ?? 4000;

      final session = ConversationSession.fromJson(sessionJson);

      // Establish Server-Sent Events stream headers immediately
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.chunkedTransferEncoding = true
        ..headers.contentType =
            ContentType('text', 'event-stream', charset: 'utf-8')
        ..headers.add('Cache-Control', 'no-cache')
        ..headers.add('Connection', 'keep-alive');

      // Helper function to emit StageEvent
      void emitStage(RequestStage stage) {
        request.response.write('data: ${jsonEncode(StageEvent(
          requestId: requestId,
          timestamp: DateTime.now(),
          stage: stage,
        ).toJson())}\n\n');
      }

      emitStage(RequestStage.preparing);

      // 1. Gather context Snapshot
      emitStage(RequestStage.gatheringContext);
      final contextReq = ContextRequest(
        workspace: session.workspace,
        activeFilePath: activeFilePath,
        selectedCode: selectedCode,
        maxTokens: maxContextTokens,
      );
      final contextSnapshot = await contextEngine.gatherContext(contextReq);

      // 2. Build prompt Package
      emitStage(RequestStage.optimizingPrompt);
      final template = _templates[templateId] ?? _templates['default']!;

      final promptPackage = promptBuilder.build(
        template: template,
        variables: {
          'workspace': session.workspace,
          'message':
              session.messages.isNotEmpty ? session.messages.last.content : '',
          ...variables,
        },
        context: contextSnapshot,
        maxContextTokens: maxContextTokens,
      );

      // 3. Select Best Ready Provider
      final provider = registry.selectBestProvider((caps) => caps.chat);
      if (provider == null || provider is! AIChatProvider) {
        final errEvent = ErrorEvent(
          requestId: requestId,
          timestamp: DateTime.now(),
          code: 'NO_PROVIDER',
          message: 'No available ready chat provider found.',
        );
        request.response.write('data: ${jsonEncode(errEvent.toJson())}\n\n');
        await request.response.flush();
        await request.response.close();
        return;
      }

      // 4. Create Cancel Token
      final token = CancellationToken();
      _activeRequests[requestId] = token;

      var aiReq = AIRequest(
        session: session,
        context: contextSnapshot,
        promptPackage: promptPackage,
        token: token,
      );

      emitStage(RequestStage.waitingProvider);

      bool loopRunning = true;
      while (loopRunning) {
        if (token.isCancelled) break;
        loopRunning = false;

        final eventStream = await provider.chat(aiReq);
        await for (final event in eventStream) {
          if (token.isCancelled) break;

          if (event is ToolCallEvent) {
            loopRunning = true;

            final toolCallId = event.toolId;
            final toolName = event.name;
            final arguments = event.arguments;

            final toolReq = ToolCallRequest(
              toolCallId: toolCallId,
              toolName: toolName,
              arguments: arguments,
            );

            final toolCtx = ToolExecutionContext(
              workspaceId: session.workspace,
              conversationId: session.id,
              requestId: requestId,
              providerId: provider.id,
              modelId: session.modelId,
              cancellationToken: token,
              sdk: sdk,
            );

            // Intercept permission if required
            final tool = toolExecutionService.registry.getTool(toolName);
            if (tool != null && tool.descriptor.requiresPermission) {
              final decision = toolExecutionService.permissionStore.getDecision(tool.descriptor.id);
              if (decision == null) {
                request.response.write('data: ${jsonEncode(ToolPermissionRequestedEvent(
                  requestId: requestId,
                  timestamp: DateTime.now(),
                  toolCallId: toolCallId,
                  toolName: toolName,
                  arguments: arguments,
                ).toJson())}\n\n');
                await request.response.flush();
              }
            }

            request.response.write('data: ${jsonEncode(ToolCallStartedEvent(
              requestId: requestId,
              timestamp: DateTime.now(),
              toolCallId: toolCallId,
              toolName: toolName,
              arguments: arguments,
            ).toJson())}\n\n');
            await request.response.flush();

            final result = await toolExecutionService.execute(toolReq, toolCtx);

            if (result.success) {
              request.response.write('data: ${jsonEncode(ToolCallCompletedEvent(
                requestId: requestId,
                timestamp: DateTime.now(),
                toolCallId: toolCallId,
                result: result,
              ).toJson())}\n\n');
            } else {
              request.response.write('data: ${jsonEncode(ToolCallFailedEvent(
                requestId: requestId,
                timestamp: DateTime.now(),
                toolCallId: toolCallId,
                code: result.errorCode ?? 'FAILED',
                message: result.output.displayText ?? 'Execution failed',
              ).toJson())}\n\n');
            }
            await request.response.flush();

            // Append tool execution history inside the conversation
            final outputStr = jsonEncode(result.toJson());
            session.messages.add(ChatMessage(
              role: ChatRole.tool,
              name: toolName,
              content: outputStr,
              timestamp: DateTime.now(),
            ));

            // Re-build prompt Package
            final optimizedPrompt = promptBuilder.build(
              template: template,
              variables: {
                'workspace': session.workspace,
                'message': session.messages.isNotEmpty ? session.messages.last.content : '',
                ...variables,
              },
              context: contextSnapshot,
              maxContextTokens: maxContextTokens,
            );

            aiReq = AIRequest(
              session: session,
              context: contextSnapshot,
              promptPackage: optimizedPrompt,
              token: token,
            );

            break; // Break the stream reading so we query the provider again in the outer loop
          } else {
            if (event is TokenChunkEvent || event is ReasoningChunkEvent) {
              emitStage(RequestStage.streaming);
            }
            request.response.write('data: ${jsonEncode(event.toJson())}\n\n');
            await request.response.flush();
          }
        }
      }

      _activeRequests.remove(requestId);
      await request.response.close();
    } catch (e) {
      final errEvent = ErrorEvent(
        requestId: requestId,
        timestamp: DateTime.now(),
        code: 'STREAM_FAILED',
        message: e.toString(),
      );
      try {
        request.response.write('data: ${jsonEncode(errEvent.toJson())}\n\n');
        await request.response.flush();
        await request.response.close();
      } catch (_) {}
    }
  }


  Future<void> handleGetProviders(HttpRequest request, String requestId) async {
    try {
      final providers = registry
          .listProviders()
          .map<Map<String, dynamic>>((p) => {
                'id': p.id,
                'name': p.name,
                'state': p.state.name,
                'priority': p.priority,
                'capabilities': p.capabilities.toJson(),
              })
          .toList();

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {'providers': providers},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  Future<void> handleGetHealth(HttpRequest request, String requestId) async {
    try {
      final healthMap = <String, dynamic>{};
      for (final p in registry.listProviders()) {
        healthMap[p.id] = p.getHealth().toJson();
      }

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {'health': healthMap},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  Future<void> handleGetModels(HttpRequest request, String requestId) async {
    try {
      final modelsList = <Map<String, dynamic>>[];
      for (final p in registry.listProviders()) {
        final models = await p.models();
        for (final m in models) {
          modelsList.add(m.toJson());
        }
      }

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {'models': modelsList},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  Future<void> handleCancel(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final targetRequestId = bodyJson['requestId'] as String?;

      if (targetRequestId != null &&
          _activeRequests.containsKey(targetRequestId)) {
        _activeRequests[targetRequestId]!.cancel();
        _activeRequests.remove(targetRequestId);
      }

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {'status': 'cancelled'},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  Future<void> handleTools(HttpRequest request, String requestId) async {
    try {
      final toolsJson = toolExecutionService.registry
          .listTools()
          .map((t) => t.descriptor.toJson())
          .toList();

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {'tools': toolsJson},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  Future<void> handlePermissionResponse(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final toolCallId = bodyJson['toolCallId'] as String?;
      final decisionStr = bodyJson['decision'] as String?;

      if (toolCallId != null && decisionStr != null) {
        final decision = PermissionDecision.values.firstWhere(
          (e) => e.name == decisionStr,
          orElse: () => PermissionDecision.deny,
        );
        toolExecutionService.resolvePermission(toolCallId, decision);
      }

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {'status': 'resolved'},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      _sendError(request, requestId, e.toString());
    }
  }

  void _sendError(HttpRequest request, String requestId, String error) {
    final response = ApiResponse(
      success: false,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: const {},
      errors: [error],
    );
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }
}
