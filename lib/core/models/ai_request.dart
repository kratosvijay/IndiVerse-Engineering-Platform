class AIRequest {
  final String prompt;
  final String context;
  final String modelName;
  final double temperature;
  final int maxTokens;
  final bool streaming;
  final List<Map<String, dynamic>> tools;
  final Map<String, dynamic> metadata;

  const AIRequest({
    required this.prompt,
    this.context = '',
    required this.modelName,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.streaming = false,
    this.tools = const [],
    this.metadata = const {},
  });
}
