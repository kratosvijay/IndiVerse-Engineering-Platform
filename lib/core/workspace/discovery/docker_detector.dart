import 'dart:io';
import 'detector.dart';

class DockerDetector implements Detector {
  @override
  String get name => "docker";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/Dockerfile');
    final directory = Directory('$rootPath/Dockerfile');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
