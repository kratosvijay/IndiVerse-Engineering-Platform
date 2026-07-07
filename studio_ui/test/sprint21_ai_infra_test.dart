import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/models/ai_models.dart';
import 'package:studio_ui/core/services/ai_service.dart';

void main() {
  group('AIService End-to-End Test Suite', () {
    late HttpServer mockServer;
    late AIService aiService;
    late int port;

    setUp(() async {
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      port = mockServer.port;
      aiService = AIService(serverUrl: 'http://localhost:$port');

      mockServer.listen((HttpRequest request) async {
        final path = request.uri.path;
        request.response.headers.add('Access-Control-Allow-Origin', '*');

        if (path == '/api/v1/ai/providers') {
          final res = {
            'success': true,
            'data': {
              'providers': [
                {
                  'id': 'mock-ai',
                  'name': 'Mock AI Assistant',
                  'state': 'ready',
                  'priority': 10,
                  'capabilities': {
                    'chat': true,
                    'streaming': true,
                    'tools': true,
                    'vision': true,
                    'embeddings': false,
                    'images': false,
                    'reasoning': true,
                  },
                },
              ],
            },
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(res));
          await request.response.close();
        } else if (path == '/api/v1/ai/health') {
          final res = {
            'success': true,
            'data': {
              'health': {
                'mock-ai': {
                  'state': 'ready',
                  'averageLatencyMs': 120,
                  'lastSuccessfulRequest': DateTime.now().toIso8601String(),
                  'consecutiveFailures': 0,
                },
              },
            },
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(res));
          await request.response.close();
        } else if (path == '/api/v1/ai/models') {
          final res = {
            'success': true,
            'data': {
              'models': [
                {
                  'id': 'mock-pro',
                  'name': 'Mock Pro',
                  'provider': 'mock-ai',
                  'contextWindow': 1000000,
                  'supportsVision': true,
                  'supportsTools': true,
                  'supportsReasoning': true,
                  'supportsJsonMode': true,
                  'supportsStreaming': true,
                },
              ],
            },
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(res));
          await request.response.close();
        } else if (path == '/api/v1/ai/cancel') {
          final res = {
            'success': true,
            'data': {'status': 'cancelled'},
          };
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(res));
          await request.response.close();
        } else if (path == '/api/v1/ai/chat') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.chunkedTransferEncoding = true
            ..headers.contentType = ContentType(
              'text',
              'event-stream',
              charset: 'utf-8',
            );

          final event1 = {
            'type': 'reasoning',
            'requestId': 'req-1',
            'timestamp': DateTime.now().toIso8601String(),
            'reasoning': 'Thinking...',
          };
          final event2 = {
            'type': 'token',
            'requestId': 'req-1',
            'timestamp': DateTime.now().toIso8601String(),
            'chunk': 'Hello',
          };
          final event3 = {
            'type': 'completed',
            'requestId': 'req-1',
            'timestamp': DateTime.now().toIso8601String(),
            'fullText': 'Hello',
          };

          request.response.write('data: ${jsonEncode(event1)}\n\n');
          await request.response.flush();
          await Future.delayed(const Duration(milliseconds: 50));
          request.response.write('data: ${jsonEncode(event2)}\n\n');
          await request.response.flush();
          await Future.delayed(const Duration(milliseconds: 50));
          request.response.write('data: ${jsonEncode(event3)}\n\n');
          await request.response.flush();
          await request.response.close();
        }
      });
    });

    tearDown(() async {
      await mockServer.close();
    });

    test('getProviders parses capabilities correctly', () async {
      final providers = await aiService.getProviders();
      expect(providers.length, 1);
      expect(providers.first['id'], 'mock-ai');
      expect(providers.first['state'], 'ready');
      expect(providers.first['capabilities']['chat'], true);
    });

    test('getHealth parses states correctly', () async {
      final health = await aiService.getHealth();
      expect(health.containsKey('mock-ai'), true);
      final pHealth = AIProviderHealth.fromJson(health['mock-ai']);
      expect(pHealth.state, AIProviderState.ready);
      expect(pHealth.averageLatency.inMilliseconds, 120);
    });

    test('getModels parses capabilities and windows', () async {
      final models = await aiService.getModels();
      expect(models.length, 1);
      expect(models.first.id, 'mock-pro');
      expect(models.first.supportsReasoning, true);
      expect(models.first.contextWindow, 1000000);
    });

    test('chatStream streams Token and Reasoning chunk events', () async {
      final session = ConversationSession(
        id: 'sess',
        title: 'Title',
        workspace: 'workspace',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
        messages: const [],
        estimatedTokens: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stream = aiService.chatStream(session: session);
      final events = await stream.toList();

      expect(events.length, 3);
      expect(events[0] is ReasoningChunkEvent, true);
      expect(events[1] is TokenChunkEvent, true);
      expect(events[2] is CompletedEvent, true);

      final tokenEv = events[1] as TokenChunkEvent;
      expect(tokenEv.chunk, 'Hello');
    });

    test('cancelRequest returns success status', () async {
      await expectLater(aiService.cancelRequest('req-1'), completes);
    });
  });
}
