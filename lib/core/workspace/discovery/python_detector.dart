import 'dart:io';
import 'detector.dart';

class PythonDetector implements Detector {
  @override
  String get name => "python";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/requirements.txt');
    final directory = Directory('$rootPath/requirements.txt');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
