import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../providers/ai_provider.dart';
import '../../providers/ai_provider_registry.dart';
import '../../conversation/conversation_manager.dart';
import '../../context/context_engine.dart';
import '../../prompt/prompt_pipeline.dart';
import '../dto/api_response.dart';

class AIController {
  final AIProviderRegistry registry;
  final ConversationManager conversationManager;
  final ContextEngine contextEngine;
  final PromptBuilder promptBuilder = PromptBuilder();

  // Map to store active request cancel tokens
  final Map<String, CancellationToken> _activeRequests = {};

  AIController({
    required this.registry,
    required this.conversationManager,
    required this.contextEngine,
  });

  Future<void> handleChat(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;

      final sessionJson = bodyJson['session'] as Map<String, dynamic>;
      final activeFilePath = bodyJson['activeFilePath'] as String?;
      final variables =
          Map<String, String>.from(bodyJson['variables'] as Map? ?? {});
      final maxContextTokens = bodyJson['maxContextTokens'] as int? ?? 4000;

      final session = ConversationSession.fromJson(sessionJson);

      // 1. Gather context Snapshot
      final contextReq = ContextRequest(
        workspace: session.workspace,
        activeFilePath: activeFilePath,
        maxTokens: maxContextTokens,
      );
      final contextSnapshot = await contextEngine.gatherContext(contextReq);

      // 2. Build prompt Package
      final defaultTemplate = const PromptTemplate(
        systemTemplate:
            'You are IndiVerse Copilot, a helpful pair programming assistant. System variables: {{workspace}}',
        userTemplate: 'Help with: {{message}}',
      );

      final promptPackage = promptBuilder.build(
        template: defaultTemplate,
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
        final response = ApiResponse(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          requestId: requestId,
          data: const {},
          errors: ['No available ready chat provider found.'],
        );
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(response.toJsonString());
        return;
      }

      // 4. Create Cancel Token
      final token = CancellationToken();
      _activeRequests[requestId] = token;

      final aiReq = AIRequest(
        session: session,
        context: contextSnapshot,
        promptPackage: promptPackage,
        token: token,
      );

      // 5. Establish Server-Sent Events stream headers
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.chunkedTransferEncoding = true
        ..headers.contentType =
            ContentType('text', 'event-stream', charset: 'utf-8')
        ..headers.add('Cache-Control', 'no-cache')
        ..headers.add('Connection', 'keep-alive');

      final eventStream = await provider.chat(aiReq);
      await for (final event in eventStream) {
        request.response.write('data: ${jsonEncode(event.toJson())}\n\n');
        await request.response.flush();
      }

      _activeRequests.remove(requestId);
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
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
      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {'tools': <Map<String, dynamic>>[]},
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
