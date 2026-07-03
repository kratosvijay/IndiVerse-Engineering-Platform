import '../tracking/token_tracker.dart';

class AIChunk {
  final String text;
  final String? finishReason;
  final TokenUsage? usage;
  final String? delta;
  final List<dynamic>? toolCalls;
  final List<dynamic>? toolResults;

  const AIChunk({
    required this.text,
    this.finishReason,
    this.usage,
    this.delta,
    this.toolCalls = const [],
    this.toolResults = const [],
  });

  @override
  String toString() => text;
}
