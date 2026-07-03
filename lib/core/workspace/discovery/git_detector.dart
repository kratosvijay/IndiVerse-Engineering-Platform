import 'dart:io';
import 'detector.dart';

class GitDetector implements Detector {
  @override
  String get name => "git";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/.git');
    final directory = Directory('$rootPath/.git');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
