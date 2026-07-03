import '../tracking/token_tracker.dart';

class AIResponse {
  final String text;
  final TokenUsage usage;
  final String finishReason;
  final List<String> citations;
  final List<Map<String, dynamic>> toolCalls;

  final String provider;
  final String model;
  final String responseId;
  final List<dynamic> toolResults;

  const AIResponse({
    required this.text,
    required this.usage,
    required this.finishReason,
    this.citations = const [],
    this.toolCalls = const [],
    this.provider = '',
    this.model = '',
    this.responseId = '',
    this.toolResults = const [],
  });
}
