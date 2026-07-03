class DetectionResult {
  final String name;
  final bool isDetected;
  final String version;
  final Map<String, dynamic> metadata;

  const DetectionResult({
    required this.name,
    required this.isDetected,
    this.version = "unknown",
    this.metadata = const {},
  });
}

abstract class Detector {
  String get name;
  Future<DetectionResult> detect(String rootPath);
}
