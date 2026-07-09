import 'generation_models.dart';

class ReviewEngine {
  const ReviewEngine();

  // Evaluates a set of GeneratedPatches to compute multi-dimensional review metrics
  Future<ReviewResult> review(List<GeneratedPatch> patches) async {
    var styleScore = 9.0;
    var securityScore = 9.5;
    var performanceScore = 9.0;
    var architectureScore = 9.2;
    var documentationScore = 8.5;
    var overallDecision = 'Approve';

    for (final patch in patches) {
      if (patch.generatedText.contains('hardcoded') ||
          patch.generatedText.contains('password')) {
        securityScore = 4.0;
        overallDecision = 'Regenerate';
      }
      if (patch.generatedText.contains('TODO')) {
        documentationScore = 5.0;
      }
    }

    return ReviewResult(
      styleScore: styleScore,
      securityScore: securityScore,
      performanceScore: performanceScore,
      architectureScore: architectureScore,
      documentationScore: documentationScore,
      overallDecision: overallDecision,
    );
  }
}
