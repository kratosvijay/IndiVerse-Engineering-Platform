class ModelConfig {
  final String name;
  final bool enableStreaming;
  final bool enableVision;

  const ModelConfig({
    required this.name,
    this.enableStreaming = true,
    this.enableVision = false,
  });
}
