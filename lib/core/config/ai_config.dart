class AIConfig {
  final String defaultModelName;
  final double defaultTemperature;
  final int defaultMaxTokens;
  final double budgetDailyLimit;

  const AIConfig({
    this.defaultModelName = 'mock-model',
    this.defaultTemperature = 0.7,
    this.defaultMaxTokens = 2048,
    this.budgetDailyLimit = 10.0,
  });
}
