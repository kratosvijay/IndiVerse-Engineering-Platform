import '../contracts/decision_record.dart';

class PolicyValidator {
  Future<bool> validate(DecisionRecord record) async {
    return record.confidence > 0.5;
  }
}
