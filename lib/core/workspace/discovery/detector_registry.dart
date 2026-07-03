import 'detector.dart';

class DetectorRegistry {
  final List<Detector> _detectors = [];

  void register(Detector detector) {
    _detectors.add(detector);
  }

  List<Detector> get detectors => List.unmodifiable(_detectors);

  Future<List<DetectionResult>> runAll(String rootPath) async {
    final results = <DetectionResult>[];
    for (final detector in _detectors) {
      try {
        final result = await detector.detect(rootPath);
        results.add(result);
      } catch (_) {
        results.add(DetectionResult(name: detector.name, isDetected: false));
      }
    }
    return results;
  }
}
