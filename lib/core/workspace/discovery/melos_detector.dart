import 'dart:io';
import 'detector.dart';

class MelosDetector implements Detector {
  @override
  String get name => "melos";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/melos.yaml');
    final directory = Directory('$rootPath/melos.yaml');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
