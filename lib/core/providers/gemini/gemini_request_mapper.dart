import '../../models/ai_request.dart';
import '../../models/capability.dart';

class GeminiRequestMapper {
  static Map<String, dynamic> mapRequest(AIRequest request) {
    final contents = [
      {
        "role": "user",
        "parts": [
          {"text": request.prompt}
        ]
      }
    ];

    final generationConfig = <String, dynamic>{
      "temperature": request.temperature,
      "maxOutputTokens": request.maxTokens,
    };

    if (request.capabilities.contains(Capability.json)) {
      generationConfig["responseMimeType"] = "application/json";
    }

    final body = <String, dynamic>{
      "contents": contents,
      "generationConfig": generationConfig,
    };

    if (request.systemInstruction != null &&
        request.systemInstruction!.isNotEmpty) {
      body["systemInstruction"] = {
        "parts": [
          {"text": request.systemInstruction!}
        ]
      };
    }

    return body;
  }
}
