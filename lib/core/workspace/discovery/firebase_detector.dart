import 'dart:io';
import 'detector.dart';

class FirebaseDetector implements Detector {
  @override
  String get name => "firebase";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/firebase.json');
    final directory = Directory('$rootPath/firebase.json');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
