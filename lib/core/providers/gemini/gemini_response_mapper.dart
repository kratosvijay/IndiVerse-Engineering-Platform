import '../../models/ai_response.dart';
import '../../tracking/token_tracker.dart';

class GeminiResponseMapper {
  static AIResponse mapResponse(Map<String, dynamic> json) {
    final candidates = json["candidates"] as List?;
    String text = "";
    String finishReason = "stop";

    if (candidates != null && candidates.isNotEmpty) {
      final first = candidates.first as Map<String, dynamic>;
      finishReason =
          (first["finishReason"] as String?)?.toLowerCase() ?? "stop";
      final content = first["content"] as Map<String, dynamic>?;
      if (content != null) {
        final parts = content["parts"] as List?;
        if (parts != null && parts.isNotEmpty) {
          text = parts
              .map((p) => (p as Map<String, dynamic>)["text"] as String? ?? "")
              .join("");
        }
      }
    }

    final usageMetadata = json["usageMetadata"] as Map<String, dynamic>?;
    TokenUsage usage = const TokenUsage();
    if (usageMetadata != null) {
      usage = TokenUsage(
        inputTokens: (usageMetadata["promptTokenCount"] as num?)?.toInt() ?? 0,
        outputTokens:
            (usageMetadata["candidatesTokenCount"] as num?)?.toInt() ?? 0,
        totalTokens: (usageMetadata["totalTokenCount"] as num?)?.toInt() ?? 0,
      );
    }

    return AIResponse(
      text: text,
      usage: usage,
      finishReason: finishReason,
    );
  }
}
