import 'dart:io';
import 'detector.dart';

class DartDetector implements Detector {
  @override
  String get name => "dart";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/pubspec.yaml');
    final directory = Directory('$rootPath/pubspec.yaml');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
