class Prompt {
  final String systemInstructions;
  final String userInput;
  final List<String> contextSnippets;
  final List<String> constraints;
  final String expectedOutput;
  final Map<String, dynamic> metadata;

  const Prompt({
    required this.systemInstructions,
    required this.userInput,
    this.contextSnippets = const [],
    this.constraints = const [],
    this.expectedOutput = '',
    this.metadata = const {},
  });
}
