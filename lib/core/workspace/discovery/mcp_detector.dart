import 'dart:io';
import 'detector.dart';

class McpDetector implements Detector {
  @override
  String get name => "mcp";

  @override
  Future<DetectionResult> detect(String rootPath) async {
    final file = File('$rootPath/mcp.json');
    final directory = Directory('$rootPath/mcp.json');
    final isDetected = await file.exists() || await directory.exists();
    return DetectionResult(name: name, isDetected: isDetected);
  }
}
