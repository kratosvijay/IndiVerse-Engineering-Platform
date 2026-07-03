class BudgetManager {
  final double dailyLimit;
  double _currentSpend = 0.0;

  BudgetManager({this.dailyLimit = 10.0});

  double get currentSpend => _currentSpend;

  void recordSpend(double cost) {
    _currentSpend += cost;
  }

  bool checkBudget(double nextCostEstimate) {
    return (_currentSpend + nextCostEstimate) <= dailyLimit;
  }

  void reset() {
    _currentSpend = 0.0;
  }
}
