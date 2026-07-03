class UsageTracker {
  double _budgetLimit = 10.0; // Daily budget limit default $10.0
  double _accumulatedSpend = 0.0;

  double get budgetLimit => _budgetLimit;
  double get accumulatedSpend => _accumulatedSpend;

  void setBudgetLimit(double limit) {
    _budgetLimit = limit;
  }

  void recordSpend(double spend) {
    _accumulatedSpend += spend;
  }

  bool isBudgetExceeded() => _accumulatedSpend >= _budgetLimit;

  void reset() {
    _accumulatedSpend = 0.0;
  }
}
