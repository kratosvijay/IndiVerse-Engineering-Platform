import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/budget/token_budget.dart';
import 'package:indiverse_developer_platform/core/agent/budget/cost_budget.dart';
import 'package:indiverse_developer_platform/core/agent/budget/execution_budget.dart';

void main() {
  group('BudgetEnforcement Tests', () {
    test('Token and cost budgets enforce consumption tracking', () {
      final token = TokenBudget(1000);
      token.consumed = 500;
      expect(token.consumed, equals(500));

      final cost = CostBudget(10.0);
      cost.consumed = 5.0;
      expect(cost.consumed, equals(5.0));

      const exec = ExecutionBudget(Duration(seconds: 10));
      expect(exec.timeLimit, equals(const Duration(seconds: 10)));
    });
  });
}
