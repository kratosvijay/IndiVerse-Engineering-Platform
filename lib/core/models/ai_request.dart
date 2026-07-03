import 'capability.dart';

class AIRequest {
  final String prompt;
  final String context;
  final String modelName;
  final double temperature;
  final int maxTokens;
  final bool streaming;
  final List<Map<String, dynamic>> tools;
  final Map<String, dynamic> metadata;
  final Set<Capability> capabilities;
  final String? systemInstruction;

  final String executionId;
  final String requestId;
  final String priority;
  final String executionMode;
  final List<String> tags;

  const AIRequest({
    required this.prompt,
    this.context = '',
    required this.modelName,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.streaming = false,
    this.tools = const [],
    this.metadata = const {},
    this.capabilities = const {},
    this.systemInstruction,
    this.executionId = '',
    this.requestId = '',
    this.priority = 'normal',
    this.executionMode = 'synchronous',
    this.tags = const [],
  });
}
