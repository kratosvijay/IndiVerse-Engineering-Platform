import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/ai_models.dart';

class AIService {
  final String serverUrl;
  final http.Client _client = http.Client();

  AIService({required this.serverUrl});

  Future<List<Map<String, dynamic>>> getProviders() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/v1/ai/providers'));
      final envelope = jsonDecode(res.body);
      if (envelope['success'] == true) {
        return List<Map<String, dynamic>>.from(
          envelope['data']['providers'] ?? [],
        );
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getHealth() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/v1/ai/health'));
      final envelope = jsonDecode(res.body);
      if (envelope['success'] == true) {
        return Map<String, dynamic>.from(envelope['data']['health'] ?? {});
      }
    } catch (_) {}
    return {};
  }

  Future<List<AIModel>> getModels() async {
    try {
      final res = await http.get(Uri.parse('$serverUrl/api/v1/ai/models'));
      final envelope = jsonDecode(res.body);
      if (envelope['success'] == true) {
        final list = envelope['data']['models'] as List? ?? [];
        return list
            .map((m) => AIModel.fromJson(m as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await http.post(
        Uri.parse('$serverUrl/api/v1/ai/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestId': requestId}),
      );
    } catch (_) {}
  }

  Stream<AIStreamEvent> chatStream({
    required ConversationSession session,
    String? activeFilePath,
    Map<String, String>? variables,
    int? maxContextTokens,
    String? requestId,
  }) {
    final controller = StreamController<AIStreamEvent>();
    final finalRequestId =
        requestId ?? 'req-${DateTime.now().millisecondsSinceEpoch}';

    scheduleMicrotask(() async {
      try {
        final request = http.Request(
          'POST',
          Uri.parse('$serverUrl/api/v1/ai/chat'),
        );
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'session': session.toJson(),
          'activeFilePath': activeFilePath,
          'variables': variables,
          'maxContextTokens': maxContextTokens,
        });

        final streamedResponse = await _client.send(request);
        if (streamedResponse.statusCode != 200) {
          controller.add(
            ErrorEvent(
              requestId: finalRequestId,
              timestamp: DateTime.now(),
              code: 'HTTP_ERROR',
              message:
                  'Server returned status code ${streamedResponse.statusCode}',
            ),
          );
          controller.close();
          return;
        }

        // Parse SSE stream
        final lineStream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in lineStream) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              final eventJson = jsonDecode(jsonStr) as Map<String, dynamic>;
              controller.add(AIStreamEvent.fromJson(eventJson));
            }
          }
        }
      } catch (e) {
        controller.add(
          ErrorEvent(
            requestId: finalRequestId,
            timestamp: DateTime.now(),
            code: 'STREAM_ERROR',
            message: e.toString(),
          ),
        );
      } finally {
        await controller.close();
      }
    });

    return controller.stream;
  }
}
