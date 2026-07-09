import 'review_models.dart';

abstract interface class ReviewAnalyzer {
  ReviewCategory get category;
  Future<ReviewMetric> analyze(String sourceCode);
}

class ArchitectureAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.architecture;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    final reasons = <String>[];
    double score = 10.0;

    if (sourceCode.contains('import \'package:flutter/') && sourceCode.contains('class Repository')) {
      score -= 2.5;
      reasons.add('Presentation tier Flutter dependencies found in Domain repository layer.');
    }

    return ReviewMetric(
      category: category,
      score: score.clamp(0.0, 10.0),
      reasons: reasons,
      recommendations: reasons.isNotEmpty ? const ['Decouple repository classes from UI package layers.'] : const [],
      confidence: 0.95,
    );
  }
}

class SecurityAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.security;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    final reasons = <String>[];
    double score = 10.0;

    if (sourceCode.contains('api_key') || sourceCode.contains('secretKey')) {
      score -= 4.0;
      reasons.add('Hardcoded secret token variable naming detected.');
    }

    return ReviewMetric(
      category: category,
      score: score.clamp(0.0, 10.0),
      reasons: reasons,
      recommendations: reasons.isNotEmpty ? const ['Utilize environment configuration providers or secure vault keys.'] : const [],
      confidence: 0.98,
    );
  }
}

class PerformanceAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.performance;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    final reasons = <String>[];
    double score = 10.0;

    if (sourceCode.contains('while (true)') || sourceCode.contains('for (var i = 0; i < 100000; i++)')) {
      score -= 2.0;
      reasons.add('Potential high execution duration loop structures identified.');
    }

    return ReviewMetric(
      category: category,
      score: score.clamp(0.0, 10.0),
      reasons: reasons,
      recommendations: reasons.isNotEmpty ? const ['Verify loop limits or utilize stream subscriptions.'] : const [],
      confidence: 0.90,
    );
  }
}

class MaintainabilityAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.maintainability;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    return const ReviewMetric(
      category: ReviewCategory.maintainability,
      score: 9.0,
      reasons: [],
      recommendations: [],
      confidence: 0.92,
    );
  }
}

class TestabilityAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.testability;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    return const ReviewMetric(
      category: ReviewCategory.testability,
      score: 9.5,
      reasons: [],
      recommendations: [],
      confidence: 0.94,
    );
  }
}

class DocumentationAnalyzer implements ReviewAnalyzer {
  @override
  ReviewCategory get category => ReviewCategory.documentation;

  @override
  Future<ReviewMetric> analyze(String sourceCode) async {
    return const ReviewMetric(
      category: ReviewCategory.documentation,
      score: 8.5,
      reasons: [],
      recommendations: [],
      confidence: 0.88,
    );
  }
}

class EngineeringReviewEngine {
  final List<ReviewAnalyzer> analyzers;

  const EngineeringReviewEngine({
    required this.analyzers,
  });

  Future<ReviewReport> runReview(String sourceCode) async {
    final metrics = <ReviewCategory, ReviewMetric>{};
    double totalScore = 0.0;

    for (final analyzer in analyzers) {
      final metric = await analyzer.analyze(sourceCode);
      metrics[analyzer.category] = metric;
      totalScore += metric.score;
    }

    final overall = analyzers.isNotEmpty ? (totalScore / analyzers.length) : 10.0;

    return ReviewReport(
      metrics: metrics,
      overallScore: overall,
    );
  }
}
