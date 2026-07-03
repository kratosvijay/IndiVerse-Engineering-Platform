import 'dart:io';
import 'detector.dart';

class NodeDetector implements Detector {
  @override
  String get name => "node";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/package.json');
    final directory = Directory('$rootPath/package.json');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
