import 'dart:async';
import 'dart:convert';
import '../../models/ai_chunk.dart';
import 'gemini_response_mapper.dart';

class GeminiStreamAdapter {
  static Stream<AIChunk> parseStream(Stream<List<int>> byteStream) async* {
    final lines =
        byteStream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        var cleanLine = line.trim();
        if (cleanLine.startsWith("[")) cleanLine = cleanLine.substring(1);
        if (cleanLine.endsWith("]"))
          cleanLine = cleanLine.substring(0, cleanLine.length - 1);
        if (cleanLine.startsWith(",")) cleanLine = cleanLine.substring(1);
        cleanLine = cleanLine.trim();

        if (cleanLine.isEmpty) continue;

        final data = jsonDecode(cleanLine) as Map<String, dynamic>;
        final response = GeminiResponseMapper.mapResponse(data);

        yield AIChunk(
          text: response.text,
          finishReason: response.finishReason,
          usage: response.usage,
          delta: response.text,
        );
      } catch (_) {
        // Yield empty/silently ignores streaming layout borders
      }
    }
  }
}
