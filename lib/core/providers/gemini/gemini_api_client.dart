import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gemini_config.dart';
import 'gemini_errors.dart';

class GeminiApiClient {
  final http.Client _client;
  final GeminiConfig config;

  GeminiApiClient({http.Client? client, this.config = const GeminiConfig()})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> generateContent({
    required String apiKey,
    required String modelName,
    required Map<String, dynamic> requestBody,
  }) async {
    final uri = Uri.parse(
        "${config.baseUrl}/${config.apiVersion}/models/$modelName:generateContent?key=$apiKey");
    final response = await _client
        .post(
          uri,
          headers: {"Content-Type": "application/json", ...config.extraHeaders},
          body: jsonEncode(requestBody),
        )
        .timeout(config.timeout);

    if (response.statusCode != 200) {
      throw GeminiErrorTranslator.translate(response.statusCode, response.body);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Stream<List<int>> generateContentStream({
    required String apiKey,
    required String modelName,
    required Map<String, dynamic> requestBody,
  }) async* {
    final uri = Uri.parse(
        "${config.baseUrl}/${config.apiVersion}/models/$modelName:streamGenerateContent?key=$apiKey");

    final request = http.Request("POST", uri);
    request.headers["Content-Type"] = "application/json";
    request.body = jsonEncode(requestBody);

    final streamedResponse =
        await _client.send(request).timeout(config.timeout);

    if (streamedResponse.statusCode != 200) {
      final responseBody = await streamedResponse.stream.bytesToString();
      throw GeminiErrorTranslator.translate(
          streamedResponse.statusCode, responseBody);
    }

    yield* streamedResponse.stream;
  }
}
