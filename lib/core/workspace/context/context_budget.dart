abstract class ContextBudgetPolicy {
  int get maxTokens;
  int get maxFiles;

  const ContextBudgetPolicy();
}

class TinyPolicy extends ContextBudgetPolicy {
  @override
  int get maxTokens => 4000;
  @override
  int get maxFiles => 5;

  const TinyPolicy();
}

class StandardPolicy extends ContextBudgetPolicy {
  @override
  int get maxTokens => 32000;
  @override
  int get maxFiles => 20;

  const StandardPolicy();
}

class ExtendedPolicy extends ContextBudgetPolicy {
  @override
  int get maxTokens => 128000;
  @override
  int get maxFiles => 100;

  const ExtendedPolicy();
}

class MaximumPolicy extends ContextBudgetPolicy {
  @override
  int get maxTokens => 1000000;
  @override
  int get maxFiles => 1000;

  const MaximumPolicy();
}
