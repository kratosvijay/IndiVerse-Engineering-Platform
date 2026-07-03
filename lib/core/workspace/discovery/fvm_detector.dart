import 'dart:io';
import 'detector.dart';

class FvmDetector implements Detector {
  @override
  String get name => "fvm";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/.fvm');
    final directory = Directory('$rootPath/.fvm');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
