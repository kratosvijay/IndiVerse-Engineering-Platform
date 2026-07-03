import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/contracts/decision_record.dart';

void main() {
  group('DecisionRecord Tests', () {
    test('Construct record metadata', () {
      const record = DecisionRecord(
        id: 'dr-1',
        version: '1.0',
        reasoning: 'reasons',
        knowledgeSources: [],
        workspaceSources: [],
        confidence: 0.9,
        estimatedCost: 0.1,
        estimatedTokens: 100,
        riskLevel: 'low',
        recommendedAction: 'continue',
      );
      expect(record.confidence, equals(0.9));
      expect(record.riskLevel, equals('low'));
    });
  });
}
